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
function load_pwm()
	pwm.setup(pwm_pin, 1000, 100)
	pwm.start(pwm_pin)
	files = file.list()
	if files["wifi.conf"] then
		file.open("wifi.conf", "r")
		local ssid = file.readline()
		file.close()
		connect_wifi(ssid, nil) --already connected esp has saved password internaly
	else
		setup_wifi()
	end
end
function setup_wifi()
	wifi.setmode(wifi.STATIONAP)
	wifi.ap.config({ssid="setupLED", auth=wifi.OPEN})
	enduser_setup.manual(true)
	enduser_setup.start(
		function()
			print("IP:" .. wifi.sta.getip())
			file.open("wifi.conf", "w")
			file.writeline(wifi.sta.gethostname())
			file.close()
			tmr.stop(0)
			print("*** You've got 5 sec to stop timer 0 ***")
			tmr.alarm(0, 5000, tmr.ALARM_SINGLE, function() dofile("main.lua") end)
		end,
		function(err, str)
			print("enduser_setup: Err #" .. err .. ": " .. str)
		end
	);
end
function connect_wifi( ssid, password )
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, password)
	tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()
		if wifi.sta.getip() == nil then
			print("trying to connecting...")
		else
			print('IP: ',wifi.sta.getip())
			tmr.stop(0)
			print("*** You've got 5 sec to stop timer 0 ***")
			tmr.alarm(0, 5000, tmr.ALARM_SINGLE, function() dofile("main.lua") end)
		end
	end)
end

load_pwm() --load previus pwm setting if exists
gpio.mode(0, gpio.INPUT, gpio.PULLUP)
if (gpio.read(0) == 0) then	--check if setup button is pressed at boot
	setup_wifi()
else
	load_wifi()
end




