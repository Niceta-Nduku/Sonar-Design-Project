using SerialPorts
using PyPlot
using FFTW

list_serialports() # show available ports

receive_one = []
receive_two = []

b = ""


ser = SerialPort("COM3:", 9600)

readavailable(ser)

#transmit and receive
write(ser, "c")

while bytesavailable(ser) < 1
    continue
end

sleep(0.05)
readavailable(ser) #removes the conversion complete line

# Get the first buffer

write(ser, "a") # Print DMA buffer
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

receive_one=split(b, ("\r\n"))

b = "" #clear b

#second buffer
write(ser, "b") # Print DMA buffer
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

receive_two=split(b, ("\r\n"))


println(length(receive_one))
println(length(receive_two))

rc1 = []
i=1

while (i<length(receive_one)-1)
    if length(receive_one[i])>5
        push!(rc1,parse(Int,(receive_one[i][1:4])))
        push!(rc1,parse(Int,(receive_one[i][5:8])))
    else
        push!(rc1,parse(Int,(receive_one[i])))
    end
    i+=1
end

echo_one = (3.3/4096).*rc1

figure()
plot(echo_one)

rc2 = []
i=1

while (i<length(receive_two)-1)
    if length(receive_two[i])>5
        push!(rc2,parse(Int,(receive_two[i][1:4])))
        push!(rc2,parse(Int,(receive_two[i][5:8])))
    else
        push!(rc2,parse(Int,(receive_two[i])))
    end
    i+=1
end

echo_2 = (3.3/4096).*rc2

figure()
plot(echo_2)

EchoOne = (3.3/4096).*receive_one
EchoTwo= (3.3/4096).*receive_two
