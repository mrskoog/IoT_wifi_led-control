pwm_pin = 4 --gpio02
local timezon = 2
local timer = nil

function setup()
	--PWM setup in init.lua
	mdns.register("light", { description="WIFI led controller", service="http"}) --register mdns name
	sntp.sync(nil,
		function(sec,usec,server)
			print('sync', sec, usec, server)
		end,
		function(error_code)
		print('error '..error_code)
		end)
	timer = require "light_timer"
end

function send_ok( cn )
	cn:send("200 OK")
end

function send_bad_request( cn )
	cn:send("Bad request - 400 error")
end

function start_server(  )
	srv=net.createServer(net.TCP)
	srv:listen(80,function(conn)
		conn:on("receive",function(cn,payload) 
		payload=string.match(payload,"^.-HTTP") --only use url data
		if string.find(payload, "/cgi") ~= nil then --check if cgi request
			print(payload)
			for word in string.gmatch(payload, "%a+=%d+") do
				print("word "..word)
				local name=string.match(word,"%a+")
				local val=string.match(word,"%d+")
				if name == "setPwm" then
					val = tonumber(val)
					if val >= 0 and val <= 100 then
						pwm.setduty(pwm_pin,tonumber(val) * 10)
						--save pwm value for next reboot
						file.open("pwm.conf", "w")
						file.writeline(val)
						file.close()
					else
						send_bad_request(cn)
						break
					end
				elseif name == "getPwm" then
					cn:send(pwm.getduty(pwm_pin))
				elseif name == "timer_start" then
					if timer.set_start(tonumber(val)) == -1 then
						send_bad_request(cn)
						break
					end
				elseif name == "timer_stop" then
					if timer.set_stop(tonumber(val)) == -1 then
						send_bad_request(cn)
						break
					end
				elseif name == "timer_repeat" then
					if timer.set_repeat(tonumber(val)) == -1 then
						send_bad_request(cn)
						break
					end
				elseif name == "timer_pwm" then
					if timer.set_pwm(tonumber(val)) == -1 then
						send_bad_request(cn)
						break
					end
				elseif name == "timer_activate" then
					if val == true then
						tmr.alarm(0, 600000, tmr.ALARM_AUTO,
							function()
								if timer.check() == 0 then
									tmr.stop(0)
								end
							end)
					elseif val == false then
						tmr.stop(0)
					else
						send_bad_request(cn)
					end
				elseif name == "get_current_time" then
					cn.send(rtctime.get())
				else
					send_bad_request(cn)
					break
				end
			end
			send_ok(cn)
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
start_server()

