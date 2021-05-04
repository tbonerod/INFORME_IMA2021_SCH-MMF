function [r] = impulseresponse
% r.S2M = @STEREO2MONO;
r.adqIR = @adqIR;
r.grafico = @grafico;
end

% function MONO = STEREO2MONO(y)
% 
%     n = size(y,2);                          %Checkeo si es mono o no
% 
%     if(n>1)
%         MONO=(1/n)*sum(y,2);                  %Si lo es, sumo todos los canales                               
%     else
%         MONO=y;                               %Sino la devuelvo tal cual                               
%     end
%     
% end

function [IR] = adqIR(medicion,filtroinverso,FS)

largox = length(filtroinverso);
largoy = length(medicion);

% Verifico el largo de los vectores, al mas corto le hago padding
if largoy ~= largox
    diflarg = largox-largoy;
    equizero = round(abs(diflarg/2));
    padding = zeros(equizero,1);
    filtroinverso = [padding; filtroinverso ; padding];   %Padding al filtro inverso
    
    % FFT a las dos seniales
    X = fft(filtroinverso);
    Y = fft(medicion);
    H = Y.*X;
    % FFT Inversa al producto obtenido
    h = ifft(H);
end
% n = 501; % largo de ventana media movil
h = h./max(abs(h));
indice1 = find(h==1,1);
if isempty(indice1)
    indice1 = find(h==-1,1);
end
% if indice1 < 501
%     k = 501 - indice1;
%     padding2 = zeros(k+1,1);
%     h = [padding2;h];
% end
% indice0 = indice1 - 250;
IR = h(indice1:end,:);
IR = IR/max(abs(IR));
end

function grafico(IR,FS,handles)
n=length(IR);
T=n/FS;
t=linspace(0,T,FS*T);
cla
plot(t,IR); title('Respuesta al impulso');
xlabel('Tiempo [s]'); ylabel('Amplitud');
grid on; grid minor;
legend('Respuesta al impulso');
set(handles.grafico,'Color',[0.97,0.97,0.97])
ylim ([-1 1])
end

