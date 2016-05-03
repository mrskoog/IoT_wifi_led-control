function load_pwm()
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
function connect_wifi( ssid, password )
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, password)
	tmr.alarm(0, 1000, 1, function()
		if wifi.sta.getip() == nil then
			print("trying to connecting...")
		else
			print('IP: ',wifi.sta.getip())
			tmr.stop(0)
			print("*** You've got 5 sec to stop timer 0 ***")
			tmr.alarm(0, 5000, 0, function() dofile("main.lua") end)
		end
	end)
end

load_pwm() --load previus pwm setting if exists
connect_wifi("ssid","password")




