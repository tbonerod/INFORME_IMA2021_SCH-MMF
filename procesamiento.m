function [q] = procesamiento
q.filtros = @bancofiltros;
q.suavizado = @suavizado;
q.schroeder = @schroeder;
q.MeanMov = @MeanMov;
q.FiltFULLBANDA = @fullband;
end

function [xoct, FcentO, xfull, MIN_LOCATION, MAX_LOCATION] = bancofiltros(RI,Fs,varargin)
% This function creater an Octave-Band Filter and a Third-Octave-Band Filter Bank
% for the frequencies between 20 and 20000 Hz. Center Frequencies are calculated
% using base-ten octave ratio (G) as indicated in CEI-61260 (2001).
    
FMIN = varargin{1};
FMAX = varargin{2};
% General Constants
G = 10^(3/10); % Bandwidth Ratio
Fr = 1000; % Reference Frequency
x = -10000:1350; % Limits

% Octave Filter Bank Generation

L1 = 1; % Octave fraction (1)
%Variables Initialization
FcentO = Fr * (G.^((x-30)/L1));  % Center Frequencies for Octave Filter Bank
FcentO(FcentO<20) = [];
FcentO(FcentO>20000) = [];
FcentO(FcentO<FMIN) = [];
FcentO(FcentO>FMAX) = [];
BankOctave = cell(1,length(FcentO));
xoct = zeros(length(FcentO),length(RI));
iFINALo = length(FcentO);
FiltOrdOct = 4;

% Filter Bank Generation
for i= 1:iFINALo
     BankOctave{i} = fdesign.octave(L1, 'Class 0', 'N,F0', FiltOrdOct, ...
     FcentO(i), Fs);
     OctaveFilter = BankOctave{i};
     FO(i) = design(BankOctave{i});
     xoct(i,:) = filter(FO(i),RI);  
end

% Full Band Filter --> butterworth pasabanda de 4to orden

orden = 4;
[b,a] = butter(orden/2,[FMIN, FMAX]/(Fs/2),'bandpass');
xfull = filter(b,a,RI);
xfull = reshape(xfull, 1, []);
FRECS_TABLAS = [31.5 63 125 250 500 1000 2000 4000 8000 16000];
j = length(FRECS_TABLAS);
k = length(FcentO);
fmin = FcentO(1);
fmax = FcentO(k);
MIN_INDX = zeros(1,j);
MAX_INDX = zeros(1,j);

for m = 1:j
    MIN_INDX(m) = abs(FRECS_TABLAS(m) - fmin);
    MAX_INDX(m) = abs(FRECS_TABLAS(m) - fmax);
end

MIN_LOCATION = find(MIN_INDX == min(MIN_INDX));
MAX_LOCATION = find(MAX_INDX == min(MAX_INDX));

end

function EDC = suavizado(y,handles)
[m] = size(y,1);

for i=1:m
    EDC(i,:) = y(i,:).^2;
end
end

function [MM, RMS_RUIDO] = MeanMov(y, FS, FcentO)

y = suavizado(y);
[m,n] = size(y);
MM = zeros(m,n);
RMS_RUIDO = zeros(m,1);
for i=1:m
    banda = FcentO(i);
    [~,RMS_RUIDO(i)] = lundeby_v2(y(i,:),FS,i,banda);
    MM(i,:) = (medfilt1(y(i,:),9600, 'truncate')).^(1/2);
    MM(i,:) = 10*log10((MM(i,:)./max(MM(i,:))).^2);
end

end

function [SCH,RMS_RUIDO] = schroeder(y,FS,FcentO)
y = suavizado(y);
[m,n] = size(y);
SCH = zeros(m,n);
RMS_RUIDO = zeros(m,1);
for i=1:m
    banda = FcentO(i);
    [~,RMS_RUIDO(i)] = lundeby_v2(y(i,:),FS,i,banda);
    SCH(i,:) = fliplr((cumsum(fliplr(y(i,:))))/(sum(y(i,:))));
    SCH(i,:) = 10*log10((SCH(i,:)./max(SCH(i,:)).^2));
end

end

function [crosspoint,RFdB] = lundeby_v2(suavizada,FS,i,banda)

suavizada = movmean(suavizada/max(suavizada),8001);
param = parameters; % cargo mi handle para funcion de regresion.

% Paso 1: obtener nivel de ruido de fondo a partir del ultimo 10% de la respuesta.
n = length(suavizada); % cantidad de muestras de la respuesta
n10 = round(0.9*n); % primer muestra del ultimo 10% de senal
tail = suavizada(n10:end); % cola de la senal
tail = rms(tail(1:end-100)); % se eleva al cuadrado
RFdB = 10*log10(tail); % obtencion del nivel de ruido de fondo
clear tail n10 % limpieza de memoria

% Paso 2: elevar respuesta al cuadrado y dividir en intervalos de 10-50 ms
% promediados. luego calcular dB para cada intervalo.
respcuad = suavizada; % elevando al cuadrado

T = n/FS; % duracion de la respuesta en segundos


if banda<126
    UU = 5;
elseif banda>126 && banda<2000
    UU = 3;
else
    UU = 1;
end
        
ms = FS*UU/100; % cantidad de muestras en el intervalo
M = floor(n/ms); % cantidad de intervalos resultantes
medias=zeros(M,1);
mediasdB=zeros(M,1);

for i = 1:M
    desde = 1+ms*(i-1);
    hasta = ms*i;
    medias(i,1) = mean(respcuad(desde:hasta)); % calculo de las medias para cada intervalo
    mediasdB(i,1) = 10*log10(medias(i)); % pasaje a dB para cada intervalo
end

% Paso 3: estimar pendiente de decaimiento a partir de una regresion lineal
% desde el comienzo de la respuesta -dividida en intervalos- hasta el
% ultimo momento en que se registra un nivel 10db superior al nivel
% estimado de RF.
j = find(mediasdB <= 10 + RFdB); % obtencion del indice del vector de medias limite de la regresion
VALORES = mediasdB(j);
VALORES(VALORES<=RFdB+5)=[];
if isempty(VALORES)
    J = j(1);
else
J = find(mediasdB>=max(VALORES),1,'last');
end

lapsosms20 = 1:J; % cantidad de lapsos de  X ms (depende de UU) que entran en la regresion
[A,B,~] = param.regression(lapsosms20,mediasdB(1:J,1)');
clear lapsos10ms j medias mediasdB

% Paso 4: estimacion preliminar del punto de cruce entre la recta constante
% de ruido de fondo y la recta que resulta de la regresion lineal
nint = (RFdB-B)/A; % punto de cruce entre las rectas
crosspoint = round((nint)*FS*(UU/100)); % crosspoint es un punto en el eje temporal
if crosspoint > n
    crosspoint = n;
end
end