using PyPlot

ion()

figure()

a = zeros(100)

for i in 1:100
	a[i] = i
end

while true
	b = rand(Int, 100) # generate random array
	clf() # this clears the current figure for the next
	plot(a,b) # this will plot a random array of values
	sleep(1) # this will wait for 1 second
end
