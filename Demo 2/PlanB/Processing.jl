using SerialPorts
using PyPlot
using FFTW


list_serialports()
array_one = []
array_two = []

b = ""


# ser = SerialPort("COM3:", 9600)
ser = SerialPort("/dev/ttyACM2", 9600)

#=================================================================
Creating a matched filter
=================================================================#

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

array_two=split(b, ("\r\n"))
#=================================================================#
println(length(array_one))
println(length(array_two))

ac1 = []
i=1

while (i<length(array_one)-1)
    push!(ac1,parse(Int,(array_one[i])))
    i+=1
end

match_one = (3.3/4096).*ac1

figure("Unprocessed Expected Echo one")
title("Unprocessed Expected Echo one")
plot(match_one)

ac2 = []
i=1

while (i<length(array_two)-1)
    push!(ac2,parse(Int,(array_two[i])))
    i+=1
end

match_two = (3.3/4096).*ac2

figure("Unprocessed Expected Echo two")
title("Unprocessed Expected Echo two")
plot(match_two)

FilterOne = (3.3/4096).*match_one
FilterTwo= (3.3/4096).*match_two
#=================================================================
Receiving process
=================================================================#
list_serialports() # show available ports

receive_one = []
receive_two = []

b = ""
# ser = SerialPort("COM3:", 9600)
ser = SerialPort("/dev/ttyACM1", 9600)

r = readavailable(ser)

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

receive_one=split(b, ("\r\n"))
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

receive_two=split(b, ("\r\n"))
#=================================================================#
println(length(receive_one))
println(length(receive_two))

rc1 = []
i=1

while (i<length(receive_one)-1)
    push!(rc1,parse(Int,(receive_one[i])))
    i+=1
end

echo_one = (3.3/4096).*rc1

figure("Unprocessed Echo one")
plot(echo_one)

rc2 = []
i=1

while (i<length(receive_two)-1)
    push!(rc2,parse(Int,(receive_two[i])))
    i+=1
end

echo_2 = (3.3/4096).*rc2

figure("Unprocessed Echo two")
plot(echo_2)

EchoOne = (3.3/4096).*receive_one
EchoTwo= (3.3/4096).*receive_two

#end of receiving

#=================================================================
 Processing begins
=================================================================#

c = 343;          # Speed of sound in air in m/s
fs = 500000;       # This is the sample rate of the sonar.
dt = 1/fs;        # This is the sample spacing
r_max = 10;        # Maximum range in metres to which to simulate.
t_max = 2*r_max/c;

t = collect(0:dt:t_max);

# t = t[0:length(y)]
r = c*t/2;

f0 = 40000;       # Centre frequency is 40 kHz
B = 2000;         # Chirp bandwidth
T = 6E-3;         # Chirp pulse length
K = B/T;          # Chirp rate

td = 0.6*T;     #i'm very skeptical about this

#=================================================================
The signals
=================================================================#

#"expected echoes"
v_tx1 = match[1:length(t)]
V_TX1 = fft(v_tx1);

v_tx2 = match[1:length(t)]
V_TX2 = fft(v_tx2);

#plots
figure("Expected Echo")
title("Expected Echo")
subplot(2,1,1)
plot(r,v_tx1)
subplot(2,1,2)
plot(r,v_tx2) #query

# received echos
v_rx1 = receive[1:length(t)]
V_RX1 = (fft(v_rx1));

v_rx2 = receive[1:length(t)]
V_RX2 = (fft(v_rx2));

#plots
figure("Unprocessed Received Echo")
title("Unprocessed Received Echo")
subplot(2,1,1)
plot(r,v_rx1)
subplot(2,1,2)
plot(r,v_rx2) #query

#=================================================================
Matched Filering
=================================================================#
#filter one
H1 = conj( V_TX1);

V_MF1 = H.*V_RX1;
v_mf1 = ifft(V_MF1);

#plots
figure("First Echo match filtered")
title("First Echo match filtered")
subplot(2,1,1)
plot(r,v_mf1)
subplot(2,1,2)
plot(V_MF1) #query

#Filter two
H2 = conj(V_TX2);

V_MF2 = H.*V_RX2;
v_mf2 = ifft(V_MF2);

#plots
figure("second Echo match filtered")
title("second Echo match filtered")
subplot(2,1,1)
plot(r,v_mf2)
subplot(2,1,2)
plot(V_MF2) #query

#=================================================================
Analytic Signal
=================================================================#

V_ANAL1 = 2*V_MF1; # make a copy and double the values
N1 = length(V_MF1);

if mod(N1,2)==0 # case N even
    neg_freq_range = Int(N1/2):N1; # Define range of “neg-freq” components
else # case N odd
    neg_freq_range = Int((N1+1)/2):N1;
end

V_ANAL1[neg_freq_range] .= 0; # Zero out neg components in 2nd half of array.
v_anal1 = ifft(V_ANAL1);

#Analytic echo 2

V_ANAL2 = 2*V_MF2; # make a copy and double the values
N2 = length(V_MF2);

if mod(N2,2)==0 # case N even
    neg_freq_range = Int(N2/2):N2; # Define range of “neg-freq” components
else # case N odd
    neg_freq_range = Int((N2+1)/2):N2;
end

V_ANAL2[neg_freq_range] .= 0; # Zero out neg components in 2nd half of array.
v_anal2 = ifft(V_ANAL2);

#=================================================================
Base band Signals
=================================================================#
j=im;

v_bb1 = v_anal1.*exp.(-j*2*pi*f0.*t);
V_BB1 = fft(v_bb1);

v_bb2 = v_anal1.*exp.(-j*2*pi*f0.*t);
V_BB2 = fft(v_bb2);

#=================================================================
Angle Calculation
this section is very wrong, it's just for understanding
=================================================================#
d =
k =
λ =

Δψ = angle( v_mf2 .* conj(v_mf1))
θ = arcsin((λ/(2*pi*d)).* (Δψ.+(k*2*pi)))

x = cos(θ)
y = sin(θ)

figure()
plot(x,y)
