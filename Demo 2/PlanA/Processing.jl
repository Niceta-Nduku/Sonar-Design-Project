using SerialPorts
using PyPlot
using FFTW

#=================================================================
Empty array
=================================================================#

dummy_one = open("dummy1.txt") do file
    read(file, String)
end

dummy_two = open("dummy2.txt") do file
    read(file, String)
end

dummy_array_one=split(dummy_one, (", "))

dummy_array_two = split(dummy_two, (", "))

#=================================================================#

da1 = []
da2 = []

for i in dummy_array_one
    if (i == "")
        continue
    end
    push!(da1,parse(Int,i))
end

ma2 = []

for i in dummy_array_two
    if (i == "")
        continue
    end
    push!(da2,parse(Int,i))
end

DummyOne = (3.3/4096).*da1
DummyTwo = (3.3/4096).*da2
#=================================================================
Load matched filter
=================================================================#
matched_one = open("Filter1.txt") do file
    read(file, String)
end

matched_two = open("Filter2.txt") do file
    read(file, String)
end

array_one=split(matched_one, (", "))

array_two = split(matched_two, (", "))

#=================================================================#
ma1 = []
ma2 = []

for i in array_one
    if (i == "")
        continue
    end
    push!(ma1,parse(Int,i))
end

for i in array_two
    if (i == "")
        continue
    end
    push!(ma2,parse(Int,i))
end

MatchOne = (3.3/4096).*ma1
MatchTwo = (3.3/4096).*ma2

for j = 1:length(MatchOne)
    MatchOne[j]=MatchOne[j]-DummyOne[j]
    MatchTwo[j]=MatchTwo[j]-DummyTwo[j]
end

#=================================================================
 Processing constants
=================================================================#
c = 343;          # Speed of sound in air in m/s
fs = 500000;       # This is the sample rate of the sonar.
dt = 1/fs;        # This is the sample spacing
r_max = 12;        # Maximum range in metres to which to simulate.
t_max = 2*r_max/c;

t = collect(0:dt:t_max);
print(length(t))

r = c*t/2;

f0 = 40000;       # Centre frequency is 40 kHz
B = 2000;         # Chirp bandwidth
T = 6E-3;         # Chirp pulse length
K = B/T;          # Chirp rate
N = length(t)
#=================================================================#
# BPF

function rect(t)
    N = length(t)
    x = zeros(N)
    for n = 1:N
        abs_t = abs(t[n])
        if abs_t > 0.5
            x[n] = 0.0
        elseif abs_t < 0.5
            x[n] = 1.0
        else
            x[n] = 0.5
        end
    end
    return x
end

δt = dt
δω = 2*pi/(N*dt)

ω = 0:δω:(N-1)*δω
f = ω/2*pi

ω0 = f0*2*pi

H = rect((ω.-ω0)/(2*pi*B))+rect((ω.-(ω0.- 2*pi/δt))/(2*pi*B))

# figure()
# cla()
# plot(f,H);

#=================================================================
Loop
=================================================================#

ion()
figure()

b = ""
i=1
list = list_serialports()

while true

    #=================================================================
    Receiving prcess
    =================================================================#

    receive_one = []
    receive_two = []

    # ser = SerialPort("COM3:", 9600)
    ser = SerialPort(list[1], 9600)

    readavailable(ser)

    #transmit and receive
    write(ser, "c")

    while bytesavailable(ser) < 1
        continue
    end

    sleep(0.05)
    readavailable(ser) #removes the conversion complete line

    #=================================================================#
    # Get the first buffer
    readavailable(ser)

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

        global b = string(b, readavailable(ser))

    end

    receive_one=split(b, ("\r\n"))

    #=================================================================#
    # Get the second buffer
    readavailable(ser)

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

        global b = string(b, readavailable(ser))

    end

    receive_two=split(b, ("\r\n"))
    #=================================================================#
    rc1 = []

    while (i<length(receive_one))
        push!(rc1,parse(Int,(receive_one[i])))
        global i+=1
    end

    echo_one = (3.3/4096).*rc1

    rc2 = []
    global i=1

    while (i<length(receive_two))
        push!(rc2,parse(Int,(receive_two[i])))
        global i+=1
    end

    echo_2 = (3.3/4096).*rc2


    for j = 1:length(echo_one)
        echo_one[j]=echo_one[j]-DummyOne[j]
        echo_2[j]=echo_2[j]-DummyTwo[j]
    end

    # figure("Unprocessed Echo one")
    # title("Unprocessed Echo one")
    # cla()
    # plot(echo_one)
    #
    # figure("Unprocessed Echo two")
    # title("Unprocessed Echo two")
    # cla()
    # plot(echo_2)
    #
    # println(length(echo_one))
    # println(length(echo_2))

    #end of receiving
    #=================================================================#

    for i = length(MatchOne):34985
        push!(MatchOne,MatchOne[29999])
        push!(MatchTwo,MatchTwo[29999])
        push!(echo_one,echo_one[29999])
        push!(echo_2,echo_2[29999])
    end

    print(length(echo_2))

    #=================================================================
    The signals
    =================================================================#

    #"expected echoes"
    v_tx1 = MatchOne
    V_TX1 = fft(v_tx1);

    v_tx2 = MatchTwo
    V_TX2 = fft(v_tx2);

    #plots
    # figure("Expected Echo")
    # title("Expected Echo")
    # subplot(2,1,1)
    # plot(r,v_tx1)
    # subplot(2,1,2)
    # plot(r,v_tx2) #query

    # received echos
    v_rx1 = echo_one
    V_RX1 = H.*(fft(v_rx1));

    v_rx2 = echo_2
    V_RX2 = H.*(fft(v_rx2));

    #=================================================================
    Matched Filering
    =================================================================#
    #filter one
    H1 = conj( V_TX1);

    V_MF1 = H.*V_RX1;
    v_mf1 = ifft(V_MF1);


    #Filter two
    H2 = conj(V_TX2);

    V_MF2 = H.*V_RX2;
    v_mf2 = ifft(V_MF2);

    #=================================================================
    Analytic Signal
    =================================================================#


    V_ANAL1 = 2*V_MF1; # make a copy and double the values

    if mod(N,2)==0 # case N even
        neg_freq_range = Int(N/2):N; # Define range of “neg-freq” components
    else # case N odd
        neg_freq_range = Int((N+1)/2):N;
    end

    V_ANAL1[neg_freq_range] .= 0; # Zero out neg components in 2nd half of array.
    v_anal1 = ifft(V_ANAL1);

    #Analytic echo 2

    V_ANAL2 = 2*V_MF2; # make a copy and double the values

    if mod(N,2)==0 # case N even
        neg_freq_range = Int(N/2):N; # Define range of “neg-freq” components
    else # case N odd
        neg_freq_range = Int((N+1)/2):N;
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
    d = 0.025
    k = 0
    λ = c/f0

    Δψ = angle.( v_bb2 .* conj(v_bb1))
    θ = asin.((λ/(2*pi*d)).* (Δψ.+(k*2*pi)))

    x = r.*cos.(θ)
    y = r.*sin.(θ)



    #=================================================================
    plots
    =================================================================#
    #plots
    # title("Unprocessed Received Echo")
    # subplot(3,1,1)
    # cla()
    # plot(r,v_rx1)
    # subplot(5,1,2)
    # cla()
    # plot(r,v_rx2) #query

    #plots
    # title("First Echo match filtered")
    # cla()
    # subplot(4,1,3)
    # plot(r,v_mf1)
    # # subplot(2,1,2)
    # # plot(f,V_MF1) #query
    #
    # #plots
    # # title("second Echo match filtered")
    # cla()
    # subplot(4,1,4)
    # plot(r,v_mf2)
    # # subplot(2,1,2)
    # # plot(f,V_MF2) #query

    # title("Analytic signal")
    # xlabel("Range in meters")
    # cla()
    # subplot(4,1,1)
    # plot(r,abs.(v_anal2))
    # subplot(2,1,2)
    # plot(r,abs.(v_anal1))

    # title("Base band signal 1")

    subplot(3,1,1)
    cla()
    plot(r,abs.(v_bb1))
    subplot(3,1,2)
    cla()
    plot(r,angle.(v_bb1)) #query

    # title("Base band signal 2")
    # cla()
    # subplot(2,1,1)
    # plot(r,abs.(v_bb2))
    # subplot(2,1,2)
    # plot(r,angle.(v_bb2)) #query

    # title("2D")
    subplot(3,1,3)
    cla()
    plot(x,y, ".")



end


    close(ser)
