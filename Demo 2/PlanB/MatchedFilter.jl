#Libraries to import
using SerialPorts
using PyPlot
using FFTW

list_serialports() # show available ports

#=================================================================
Creating a matched filter
=================================================================#

readavailable(ser)

array_one = []
array_two = []

b = ""
# Start a conversion
# Read from first transducer
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

array_one=b
# Read from second transducer
#=================================================================#
readavailable(ser)
b = ""

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

array_two=b
#=================================================================#



file = open("FilterOne.txt", "w")
write(file,array_one)
close(file);

file = open("FilterTwo.txt", "w")
write(file, array_two)
close(file);
