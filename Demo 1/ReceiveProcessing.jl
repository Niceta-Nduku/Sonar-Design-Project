#Libraries to import
using SerialPorts
using PyPlot
using FFTW 

list_serialports() # show available ports
b = ""
y = []

# ser = SerialPort("COM3:", 9600) 
ser = SerialPort("/dev/ttyACM1", 9600) 

r = readavailable(ser)

# Start a conversion
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

close(ser)

y=split(b, ("\r\n"))

println(length(y))   


rc = []
i =1

while (i<length(y)-1)

    push!(rc,parse(Int,(y[i])))        

    j+=1
end

receive = (3.3/4096).*rc

figure()
plot(receive)

