#Libraries to import
using SerialPorts
using PyPlot
using FFTW

list_serialports() # show available ports

array_one = []
array_two = []

b = ""


# ser = SerialPort("COM3:", 9600)
ser = SerialPort("/dev/ttyACM0", 9600)

readavailable(ser)

# Start a conversion
#=================================================================#
write(ser, "c")

while bytesavailable(ser) < 1
    continue
end
sleep(0.05)
r = readavailable(ser)

# Get the values
write(ser, "p") # Print DMA buffer
while bytesavailable(ser) < 1
    continue # wait for a response
end

while true
    if bytesavailable(ser) < 2
        sleep(0.005) # Wait and check again
        if bytesavailable(ser) < 1
            break
        end
    end
    b = string(b, readavailable(ser))

end

array_one=split(b, ("\r\n"))
#=================================================================#
write(ser, "d")

while bytesavailable(ser) < 1
    continue
end
sleep(0.05)
r = readavailable(ser)

# Get the values
write(ser, "p") # Print DMA buffer
while bytesavailable(ser) < 1
    continue # wait for a response
end

while true
    if bytesavailable(ser) < 2
        sleep(0.005) # Wait and check again
        if bytesavailable(ser) < 1
            break
        end
    end
    b = string(b, readavailable(ser))

end

close(ser)

array_two=split(b, ("\r\n"))
#=================================================================#
println(length(array_one))
println(length(array_two))

ac1 = []
i=1

while (i<length(array_one)-1)
    push!(ac,parse(Int,(array_one[i])))
    i+=1
end

match_one = (3.3/4096).*ac1

figure("Unprocessed Expected Echo one")
plot(match_one)

ac2 = []
i=1

while (i<length(array_two)-1)
    push!(ac2,parse(Int,(array_two[i])))
    i+=1
end

match_two = (3.3/4096).*ac2

figure("Unprocessed Expected Echo two")
plot(match_two)

FilterOne = (3.3/4096).*match_one
FilterTwo= (3.3/4096).*match_two

file = open("FilterOne.txt", "w")
write(file,"[")
for n=1:length(FilterOne)
   write(file,"$(Int(round((FilterOne[n]))),");
end
write(file,"]")
close(file);

file = open("FilterTwo.txt", "w")
write(file,"[")
for n=1:length(FilterTwo)
   write(file,"$(Int(round((FilterTwo[n]))),");
end
write(file,"]")
close(file);
