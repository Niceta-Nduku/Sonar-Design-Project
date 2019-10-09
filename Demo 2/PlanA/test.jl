using PyPlot

ion()

figure()

a = zeros(100)

for i in 1:100
	a[i] = i
end

while true
	b = rand(Int, 100) # generate random array
	c = rand(Int, 100) # generate random array
	d = rand(Int, 100) # generate random array
	z = [b,c,d]
	clf() # this clears the current figure for the next
	subplot(311)
	plot(a,b)
	subplot(312)
	plot(a,c)
	subplot(313)
	plot(a,d)

	# plot(a,c) # this will plot a random array of values
	# plot(a,d) # this will plot a random array of values
	sleep(1) # this will wait for 1 second
end
