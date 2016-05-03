pwm_pin = 4 --gpio02

function setup_pwm()
	pwm.setup(pwm_pin, 1000, 100)
	pwm.start(pwm_pin)
	files = file.list()
	if files["pwm.conf"] then
		file.open("pwm.conf", "r")
		local val = file.readline()
		pwm.setduty(pwm_pin,tonumber(val) * 10)
		file.close()
	end
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

setup_pwm()
mdns.register("light", { description="WIFI led controller", service="http"}) --register mdns name
print("starting server")
start()

