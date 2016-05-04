pwm_pin = 4 --gpio02
time = {0, 0, 0}
timezon = 2
DST = 0

function setup()
	--PWM setup in init.lua
	mdns.register("light", { description="WIFI led controller", service="http"}) --register mdns name
	get_time()
	tmr.alarm(0, 1000, tmr.ALARM_AUTO, rtc)
end

function rtc()
	time[3] = time[3] + 1
	if time[3] == 12 then 
		time[3] = 0
		time[2] = time[2] + 1
		if time[2] == 12 then
			time[2] = 0
			time[1] = time[1] + 1
			if time[1] == 24 then
				time[1] = 0
				get_time() --sync time with net
			end
		end
	end
end

function split_time_str( s )
	local i = 1
	for value in string.gmatch(s, "%d%d") do
		time[i] = tonumber(value)
		i = i + 1
	end
	time[i] = time[1] + timezon + DST --add daylight saving time and timezon offset
end

function get_time(  )
	conn=net.createConnection(net.TCP, 0) 
	conn:on("connection",function(conn, payload)
			conn:send("HEAD / HTTP/1.1\r\n".. 
					"Host: google.com\r\n"..
					"Accept: */*\r\n"..
					"User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
					"\r\n\r\n") 
	end)
	conn:on("receive", function(conn, payload)
		timestr = (string.sub(payload,string.find(payload,"Date: ")+23,string.find(payload,"Date: ")+31))
		conn:close()
		tmr.stop(0)
		split_time_str(timestr)
		tmr.alarm(0, 5000, 1, rtc)
		wifi.sta.disconnect()
	end) 
	conn:connect(80,'google.com')
end

function start_server(  )
	srv=net.createServer(net.TCP)
	srv:listen(80,function(conn)
		conn:on("receive",function(cn,payload) 
        payload=string.match(payload,"^.-HTTP") --only use url data
		if string.find(payload, "/pwm") ~= nil then --check if cgi request
            print(payload)
			for word in string.gmatch(payload, "%a+=%d+") do
				print("word "..word)
				local name=string.match(word,"%a+")
				local val=string.match(word,"%d+")
				if name == "setPwm" then
                    --cn.send("PWM set")
					--set pwm value
                    print("pwm set "..tonumber(val) * 10)
					pwm.setduty(pwm_pin,tonumber(val) * 10)
					--save pwm value for next reboot
					file.open("pwm.conf", "w")
					file.writeline(val)
					file.close()
				elseif name == "getPwm" then
					cn:send(pwm.getduty(pwm_pin))
				else
					cn:send("Bad request - 400 error")
				end
			end
		elseif string.find(payload, "/favicon.ico") then
			cn:send("File not found - 404 error")
		else
			--send index.html
			local webpage = file.open("index.html","r")
			if webpage == true then
				cn:send(file.read())
				file.close() 
			else
				cn:send("internal server error - 500 error")
			end
		end
		cn:close()
		end)
	end)
	print("server started")
end

setup()
print("starting server")
start()

