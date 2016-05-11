local light_timer = {}

--start_time: timer start time in unix-timestamp (seconds)
function light_timer.set_start( start_time )
	if start_time < light_timer["stop"] and start_time > rtctime.get() then
		light_timer["start"] = start_time
		return 0
	end
	return -1
end

--stop_time: timer stop time in unix-timestamp (seconds)
function light_timer.set_stop( stop_time )
	if  stop_time > light_timer["start"] and stop_time > rtctime.get() then
		light_timer["stop"] = stop_time
		return 0
	end
	return -1
end

--repeat_alarm: time between repeats in seconds
function light_timer.set_repeat( repeat_alarm )
	if repeat_alarm <= 0 then
		light_timer["repeat_alarm"] = repeat_alarm
		return 0
	end
	return -1
end

--pwm_val: pwm value during on time
function light_timer.set_pwm( pwm_val )
	if pwm_val > 0 and pwm_val <= 1024 then
		light_timer["pwm"] = pwm_val
		return 0
	end
	return -1
end

function light_timer.get_start(  )
	return light_timer["start"]
end

function light_timer.get_stop(  )
	return light_timer["stop"]
end

function light_timer.get_repeat(  )
	return light_timer["repeat_alarm"]
end

function light_timer.clear(  )
	light_timer["start"] = -1
	light_timer["stop"] = -1
	light_timer["repeat_alarm"] = -1
end

-- poll this function to run timer
-- returns: 0 if timer event is compleat and no repeat time is set
-- 			1 if led is in on state
-- 			2 if timer is waiting to turn on led
function light_timer.check(  )
	local now = rtctime.get()
	if now >= light_timer["start"] and now <= light_timer["stop"] then
		pwm.setduty(pwm_pin,pwm_val)
		return 1
	elseif now > light_timer["stop"] then
		if light_timer["repeat_alarm"] == 0 then
			return 0
		else
			light_timer["start"] = light_timer["start"] + light_timer["repeat_alarm"]
			light_timer["stop"] = light_timer["stop"] + light_timer["repeat_alarm"]
		end
	end
	return -1
end

--default
light_timer["start"] = 0
light_timer["stop"] = 1
light_timer["repeat_alarm"] = 0
light_timer["pwm"] = 1024
return light_timer

--debug
-- light_timer.set(1,2,0,100)
-- print(light_timer.get_start())
-- print(light_timer.get_stop())
-- print(light_timer.get_repeat())
-- print(light_timer.check())