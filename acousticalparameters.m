function varargout = acousticalparameters(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @acousticalparameters_OpeningFcn, ...
                   'gui_OutputFcn',  @acousticalparameters_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function varargout = acousticalparameters_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

%% CONFIGURACIONES por defecto al abrir la GUI

function acousticalparameters_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

handles.nrobanda = 6; % banda por defecto a graficar: 6 --> 1 KHz
handles.xHz = 1000;

movegui('center'); % Centrar la GUI

set(handles.boton_sch, 'Value', 1)
set(handles.boton_MM, 'Value', 0)
% Update handles structure
guidata(hObject, handles)

%% CALLBACKS DE MENUES

function menu_cargar_medicion_Callback(hObject, eventdata, handles)
% En algunos SO no aparece el titulo del cuadro de texto
[filemedicion,pathmedicion] = uigetfile('*.wav','Seeleccione la grabacion realizada');
[filefiltroinverso,pathfiltroinverso] = uigetfile('*.wav','Seeleccione el filtro inverso asociado');
try
    path1 = fullfile(pathmedicion,filemedicion);
    [f,n,e] = fileparts(path1);
    path2 = fullfile(pathfiltroinverso,filefiltroinverso);
catch
    msgbox('No se pudo acceder a los archivos requeridos','Error')
    return
end
try
    [medicion,FS1] = audioread(path1);
	[filtroinverso,FS2] = audioread(path2);
catch
    msgbox('Se produjo un error al leer los archivos seleccionados','Error')
    return
end
if FS1 == FS2
    data = guidata(hObject);
    data.medicion = medicion;
    data.filtroinverso = filtroinverso;
    data.FSmed = FS1;
    guidata(hObject,data)
    msgbox('Medicion y filtro inverso cargados correctamente. Intente calcular la IR!','Adquisicion completada')
else
    msgbox('Las frecuencias de sampleo de los tracks a convolucionar no coinciden. Compruebe no haber cometido un error e intentelo de nuevo.','Error')
end
set(handles.boton_ir,'enable','on')

set(handles.titulo, 'String', n)

function menu_cargar_respuesta_Callback(hObject, eventdata, handles)
data = guidata(hObject);
[filerespuesta,pathrespuesta] = uigetfile('*.wav','Seeleccione la respuesta al impulso');
try
    path = fullfile(pathrespuesta,filerespuesta);
    [f,n,e] = fileparts(path);
    data.n = n;
catch
    msgbox('No se pudo acceder a la respuesta al impulso','Error')
    return
end
try
    [IR,FS] = audioread(path);
    
    %% Recorto la IR --> trabajo todo desde su m?ximo en adelante
    
    IND_MAX = find(max(abs(IR))==abs(IR));
    IR = IR(IND_MAX:end,:);
    IR = IR/max(abs(IR)); % normalizo
    
catch
    msgbox('Se produjo un error al leer los archivos seleccionados.','Error.')
    return
end
data = guidata(hObject);
data.IR = IR;
data.FS = FS;
guidata(hObject,data);

set(handles.titulo, 'String', n)
set(handles.boton_sch,'enable','on')
set(handles.boton_MM,'enable','on')
set(handles.ACOTAR,'enable','on')
set(handles.boton_parametros,'enable','on')
set(handles.menu_graficos,'enable','on')
set(handles.menu_respuesta,'enable','on')
set(handles.menu_respuesta,'Checked','on')
impulse = impulseresponse;
impulse.grafico(data.IR,data.FS,handles)
set(handles.tablaparametros,'Data',[])

function menu_guardar_respuesta_Callback(hObject, eventdata, handles)
data = guidata(hObject);
try
    [filerespuesta,pathrespuesta] = uiputfile('.wav','Exportar respuesta al impulso obtenida','default.wav');
    path = fullfile(pathrespuesta,filerespuesta);
catch
    msgbox('No se pudo guardar el archivo ya que no se especifico una ruta correcta','Error');
    return
end
try
    audiowrite(path,data.IR,data.FS);
catch
    msgbox('Se produjo un error en la generacion del archivo de formato .wav','Error');
end

function menu_guardar_parametros_Callback(hObject, eventdata, handles)
data = guidata(hObject);

if get(handles.boton_sch,'value') > get(handles.boton_MM,'value')
    TABLA{1,4} = 'Suavizado Schroeder';
else
    TABLA{1,3} = 'Suavizado filtro mediana m?vil';
end

F1 = {'31.5 Hz','63 Hz','125 Hz','250 Hz','500 Hz','1 kHz','2 kHz','4 kHz','8 kHz','16 kHz','Banda Completa'};     
TABLA{2,2} = 'edt'; TABLA{2,3} = 'r2edt';
TABLA{2,4} = 't20'; TABLA{2,5} = 'r2t20';
TABLA{2,6} = 't30'; TABLA{2,7} = 'r2t30';

for i=1:11
    TABLA{i+2,1} = F1{i};
    TABLA{i+2,2} = data.tabla.TOT.edt(i);
    TABLA{i+2,3} = data.tabla.TOT.r2edt(i);
    TABLA{i+2,4} = data.tabla.TOT.t20(i);
    TABLA{i+2,5} = data.tabla.TOT.r2t20(i);
    TABLA{i+2,6} = data.tabla.TOT.t30(i);
    TABLA{i+2,7} = data.tabla.TOT.r2t30(i);
end

try
    [fileparametros,pathparametros] = uiputfile('.xls','Exportar planilla con los parametros', 'default.xls');
    path = fullfile(pathparametros,fileparametros);
catch
    msgbox('No se pudo guardar el archivo ya que no se especifico una ruta correcta','Error');
    return
end

try
    xlswrite(path,TABLA)
catch
    msgbox('Se produjo un error en la generacion del archivo de formato .xls','Error');
end

function menu_respuesta_Callback(hObject, eventdata, handles)
data = guidata(hObject);
i = impulseresponse;
set(handles.menu_respuesta,'Checked','on')
set(handles.menu_estimaciones,'Checked','off')
i.grafico(data.IR,data.FS,handles)

function menu_estimaciones_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
set(handles.menu_respuesta,'Checked','off')
set(handles.menu_estimaciones,'Checked','on')
p.graficos(data,handles)


%% SECCION BOTONES

function botonera_suavizado_SelectionChangedFcn(hObject, eventdata, handles)
% Tiene que existir esta funcion para cambiar valores en botonera

function boton_ir_Callback(hObject, eventdata, handles)
data = guidata(hObject);
impulse = impulseresponse;
IR = impulse.adqIR(data.medicion,data.filtroinverso,data.FSmed);
data.IR = IR;
data.FS = data.FSmed;
guidata(hObject,data)
impulse.grafico(data.IR,data.FS,handles)

set(handles.boton_sch,'enable','on')
set(handles.boton_MM,'enable','on')
set(handles.ACOTAR,'enable','on')
set(handles.menu_guardar_respuesta,'enable','on')
set(handles.menu_graficos,'enable','on')
set(handles.menu_respuesta,'enable','on')
set(handles.menu_respuesta,'Checked','on')
set(handles.menu_estimaciones,'Checked','off')
set(handles.boton_parametros,'enable','on')
set(handles.boton_ir,'enable','off')

%% Boton Parametros
function boton_parametros_Callback(hObject, eventdata, handles)

data = guidata(hObject);
proceso = procesamiento;
parametros = parameters;

if get(handles.ACOTAR,'value') == 1
    FREC_MIN  = str2double(get(handles.freq_min,'String'));
    FREC_MAX = str2double(get(handles.freq_max,'String'));
else
    FREC_MIN = 20;
    FREC_MAX = 20000;
end

% CONTEMPLO MAL INGRESO POR PARTE DEL USUARIO

% El valor para acotar debe ser numerico
try
    if isnan(FREC_MIN) || isnan(FREC_MAX)
        a = 5 + a; % tiro un error cualquiera para que salte el catch
    end
catch
    msgbox('Debe introducir un valor numerico para acotar el rango de analisis','Error')
    return
end
% El valor Fmin debe ser menor que Fmax
try
    if FREC_MIN > FREC_MAX
        a = 5 + a; % tiro un error cualquiera para que salte el catch
    end
catch
    msgbox('El valor de "Frec. min." debe ser menor que el de "Frec. max."','Error')
    return
end
% El rango tiene que ser de 20 a 20k Hz
try
    if (FREC_MIN < 20) || (FREC_MAX > 20000)
        a = 5 + a; % tiro un error cualquiera para que salte el catch
    end
catch
    msgbox('El rango de frecuencias a acotar debe estar entre 20 Hz y 20k Hz','Error')
    return
end

% Filtro la senal en Oct o FullBand
[xoct,FcentO, xfull, MIN_LOC, MAX_LOC] = proceso.filtros(data.IR,data.FS,FREC_MIN,FREC_MAX);

% Elige entre procesamiento por SCHR o MMF
if get(handles.boton_sch, 'Value') > get(handles.boton_MM, 'Value')
    [data.SCHoct,data.RFoct] = proceso.schroeder(xoct,data.FS,FcentO);
    [data.SCHfull,data.RFfull] = proceso.schroeder(xfull,data.FS, FcentO);
    
    data.SUAVoct = data.SCHoct;
    data.SUAVfull = data.SCHfull;
    data.SUAVtot = zeros(11,length(data.SUAVoct));
    [P,~] = size(data.SUAVoct);
    data.MIN_LOC = MIN_LOC;
    data.MAX_LOC = MAX_LOC;
    data.SUAVtot((MIN_LOC:(P+MIN_LOC-1)),:) = data.SUAVoct;
    data.SUAVtot(11,:) = data.SUAVfull;
else
    [data.MMoct,data.RFoct] = proceso.MeanMov(xoct,data.FS,FcentO);
    [data.MMfull,data.RFfull] = proceso.MeanMov(xfull,data.FS, FcentO);
    
    data.SUAVoct = data.MMoct;
    data.SUAVfull = data.MMfull;
    data.SUAVtot = zeros(11,length(data.SUAVoct));
    [P,~] = size(data.SUAVoct);
    data.MIN_LOC = MIN_LOC;
    data.MAX_LOC = MAX_LOC;
    data.SUAVtot((MIN_LOC:(P+MIN_LOC-1)),:) = data.SUAVoct;
    data.SUAVtot(11,:) = data.SUAVfull;
end

% Cargo la data de los nros de bandas con los que voy a trabajar cuando el
% usuario esta acotando
data.MIN_LOC = MIN_LOC;
data.MAX_LOC = MAX_LOC;

% Guardo la data por Oct y FullBand en una unica matriz
[R,~] = size(xoct);
xtot = zeros(11,length(xoct));
xtot((MIN_LOC:(R+MIN_LOC-1)),:) = xoct;
xtot(11,:) = xfull;

data.RFtot = zeros(11,1);
data.RFtot((MIN_LOC:(R+MIN_LOC-1))) = data.RFoct;
data.RFtot(11) = data.RFfull;

% pasaje a dB y normalizacion en forma "vectorizada" o matricial --> para
% los graficos
n = length(xoct(1,:));
xoct = xoct.^2;
xfull = xfull.^2;
Mxoct = max(xoct,[],2);
Mxfull = max(xfull,[],2);
vect1 = ones(1,n);
Mxoct = Mxoct*vect1;
Mxfull = Mxfull*vect1;
xoct = xoct./Mxoct;
xfull = xfull./Mxfull;
data.dBxoct = 10*log10(xoct);
data.dBxfull = 10*log10(xfull);
data.dBxtot = zeros(11,length(xoct));
data.dBxtot((MIN_LOC:(R+MIN_LOC-1)),:) = data.dBxoct;
data.dBxtot(11,:) = data.dBxfull;

bandas = length(FcentO);

clear n xoct vect1 xfull xtot %borrar variables accesorias lo antes posible

data.tabla.oct.edt = zeros(bandas,1);
data.tabla.oct.t20 = zeros(bandas,1);
data.tabla.oct.t30 = zeros(bandas,1);
data.tabla.oct.r2edt = zeros(bandas,1);
data.tabla.oct.r2t20 = zeros(bandas,1);
data.tabla.oct.r2t30 = zeros(bandas,1);
data.regresiones.oct.Aedt = zeros(1,bandas);
data.regresiones.oct.Bedt = zeros(1,bandas);
data.regresiones.oct.r2edt = zeros(1,bandas);
data.regresiones.oct.At20 = zeros(1,bandas);
data.regresiones.oct.Bt20 = zeros(1,bandas);
data.regresiones.oct.r2t20 = zeros(1,bandas);
data.regresiones.oct.At30 = zeros(1,bandas);
data.regresiones.oct.Bt30 = zeros(1,bandas);
data.regresiones.oct.r2t30 = zeros(1,bandas);

data.tabla.full.edt = zeros(1,1);
data.tabla.full.t20 = zeros(1,1);
data.tabla.full.t30 = zeros(1,1);
data.tabla.full.r2edt = zeros(1,1);
data.tabla.full.r2t20 = zeros(1,1);
data.tabla.full.r2t30 = zeros(1,1);

% CALCULO PARAMETROS OCTAVAS
for m=1:bandas
    banda = data.SUAVoct(m,:);
    
    [p0,p5,p10,p25,p35] = parametros.regressionlimits(banda);
    
    [data.regresiones.oct.Aedt(m),data.regresiones.oct.Bedt(m),data.tabla.oct.r2edt(m)] = parametros.regression(p0:p10,banda(p0:p10));
    [data.regresiones.oct.At20(m),data.regresiones.oct.Bt20(m),data.tabla.oct.r2t20(m)] = parametros.regression(p5:p25,banda(p5:p25));
    [data.regresiones.oct.At30(m),data.regresiones.oct.Bt30(m),data.tabla.oct.r2t30(m)] = parametros.regression(p5:p35,banda(p5:p35));
    
    data.tabla.oct.edt(m) = round((-60)/(data.regresiones.oct.Aedt(m)*data.FS),3);
    data.tabla.oct.t20(m) = round((-60)/(data.regresiones.oct.At20(m)*data.FS),3);
    data.tabla.oct.t30(m) = round((-60)/(data.regresiones.oct.At30(m)*data.FS),3);
  
end

% CALCULO PARAMETROS FULL BANDA
fullbanda = data.SUAVfull;
[p0,p5,p10,p25,p35] = parametros.regressionlimits(fullbanda);
[data.regresiones.full.Aedt,data.regresiones.full.Bedt,data.tabla.full.r2edt] = parametros.regression(p0:p10,fullbanda(p0:p10));
[data.regresiones.full.At20,data.regresiones.full.Bt20,data.tabla.full.r2t20] = parametros.regression(p5:p25,fullbanda(p5:p25));
[data.regresiones.full.At30,data.regresiones.full.Bt30,data.tabla.full.r2t30] = parametros.regression(p5:p35,fullbanda(p5:p35));

data.tabla.full.edt = round((-60)/(data.regresiones.full.Aedt*data.FS),3);
data.tabla.full.t20 = round((-60)/(data.regresiones.full.At20*data.FS),3);
data.tabla.full.t30 = round((-60)/(data.regresiones.full.At30*data.FS),3);

% Cargo todo en una misma matriz con la data ordenada
data.tabla.TOT.edt = zeros(11,1);
data.tabla.TOT.t20 = zeros(11,1);
data.tabla.TOT.t30 = zeros(11,1);
data.tabla.TOT.r2edt = zeros(11,1);
data.tabla.TOT.r2t20 = zeros(11,1);
data.tabla.TOT.r2t30 = zeros(11,1);

[P,~] = size(data.tabla.oct.edt);

data.tabla.TOT.edt((MIN_LOC:(P+MIN_LOC-1))) = data.tabla.oct.edt;
data.tabla.TOT.t20((MIN_LOC:(P+MIN_LOC-1))) = data.tabla.oct.t20;
data.tabla.TOT.t30((MIN_LOC:(P+MIN_LOC-1))) = data.tabla.oct.t30;
data.tabla.TOT.r2edt((MIN_LOC:(P+MIN_LOC-1))) = data.tabla.oct.r2edt;
data.tabla.TOT.r2t20((MIN_LOC:(P+MIN_LOC-1))) = data.tabla.oct.r2t20;
data.tabla.TOT.r2t30((MIN_LOC:(P+MIN_LOC-1))) = data.tabla.oct.r2t30;

data.tabla.TOT.edt(11) = data.tabla.full.edt;
data.tabla.TOT.t20(11) = data.tabla.full.t20;
data.tabla.TOT.t30(11) = data.tabla.full.t30;
data.tabla.TOT.r2edt(11) = data.tabla.full.r2edt;
data.tabla.TOT.r2t20(11) = data.tabla.full.r2t20;
data.tabla.TOT.r2t30(11) = data.tabla.full.r2t30;

% Unifico los otros parametros de oct y full
data.regresiones.TOT.Aedt = zeros(1, 11);
data.regresiones.TOT.Aedt(MIN_LOC:(P+MIN_LOC-1)) = data.regresiones.oct.Aedt;
data.regresiones.TOT.Aedt(11) = data.regresiones.full.Aedt;

data.regresiones.TOT.Bedt = zeros(1,11);
data.regresiones.TOT.Bedt(MIN_LOC:(P+MIN_LOC-1)) = data.regresiones.oct.Bedt;
data.regresiones.TOT.Bedt(11) = data.regresiones.full.Bedt;

data.regresiones.TOT.r2edt = zeros(1,11);
data.regresiones.TOT.r2edt(MIN_LOC:(P+MIN_LOC-1)) = data.tabla.oct.r2edt;
data.regresiones.TOT.r2edt(11) = data.tabla.full.r2edt;

data.regresiones.TOT.At20 = zeros(1,11);
data.regresiones.TOT.At20(MIN_LOC:(P+MIN_LOC-1)) = data.regresiones.oct.At20;
data.regresiones.TOT.At20(11) = data.regresiones.full.At20;

data.regresiones.TOT.Bt20 = zeros(1,11);
data.regresiones.TOT.Bt20(MIN_LOC:(P+MIN_LOC-1)) = data.regresiones.oct.Bt20;
data.regresiones.TOT.Bt20(11) = data.regresiones.full.Bt20;

data.regresiones.TOT.r2t20 = zeros(1,11);
data.regresiones.TOT.r2t20(MIN_LOC:(P+MIN_LOC-1)) = data.tabla.oct.r2t20;
data.regresiones.TOT.r2t20(11) = data.tabla.full.r2t20;

data.regresiones.TOT.At30 = zeros(1,11);
data.regresiones.TOT.At30(MIN_LOC:(P+MIN_LOC-1)) = data.regresiones.oct.At30;
data.regresiones.TOT.At30(11) = data.regresiones.full.At30;

data.regresiones.TOT.Bt30 = zeros(1,11);
data.regresiones.TOT.Bt30(MIN_LOC:(P+MIN_LOC-1)) = data.regresiones.oct.Bt30;
data.regresiones.TOT.Bt30(11) = data.regresiones.full.Bt30;

data.regresiones.TOT.r2t30 = zeros(1,11);
data.regresiones.TOT.r2t30(MIN_LOC:(P+MIN_LOC-1)) = data.tabla.oct.r2t30;
data.regresiones.TOT.r2t30(11) = data.tabla.full.r2t30;

% PLOTEO EN GUI
% Seteo para que el plot por defecto sea el de banda de 1k Hz
data.xHz = 1000;
data.nrobanda = 6;
parametros.graficos(data,handles)
guidata(hObject,data)

% HABILITO MENUES EN GUI
set(handles.menu_guardar_parametros,'enable','on')
set(handles.menu_bandas,'enable','on')
parametros.menuchecks(handles)
set(handles.menu_1khz_oct,'Checked','on')

if 31.5 < FREC_MIN
    set(handles.menu_31hz_oct, 'enable', 'off')
else
    set(handles.menu_31hz_oct, 'enable', 'on')
end
if 63 < FREC_MIN
    set(handles.menu_63hz_oct, 'enable', 'off')
else
    set(handles.menu_63hz_oct, 'enable', 'on')
end
if 125 < FREC_MIN
    set(handles.menu_125hz_oct, 'enable', 'off')
else
    set(handles.menu_125hz_oct, 'enable', 'on')
end
if 250 < FREC_MIN
    set(handles.menu_250hz_oct, 'enable', 'off')
else
    set(handles.menu_250hz_oct, 'enable', 'on')
end
if 500 < FREC_MIN
    set(handles.menu_500hz_oct, 'enable', 'off')
else
    set(handles.menu_500hz_oct, 'enable', 'on')
end

if 2000 > FREC_MAX
    set(handles.menu_2khz_oct, 'enable', 'off')
else
    set(handles.menu_2khz_oct, 'enable', 'on')
end
if 4000 > FREC_MAX
    set(handles.menu_4khz_oct, 'enable', 'off')
else
    set(handles.menu_4khz_oct, 'enable', 'on')
end
if 8000 > FREC_MAX
    set(handles.menu_8khz_oct, 'enable', 'off')
else
    set(handles.menu_8khz_oct, 'enable', 'on')
end
if 16000 > FREC_MAX
    set(handles.menu_16khz_oct, 'enable', 'off')
else
    set(handles.menu_16khz_oct, 'enable', 'on')
end

set(handles.menu_graficos,'enable','on')
set(handles.menu_estimaciones,'enable','on')
set(handles.menu_estimaciones,'checked','on')
set(handles.menu_respuesta,'checked','off')
set(handles.boton_ir,'enable','off')

%% SECCION CHECK BOX 

%% Acotar
function ACOTAR_Callback(hObject, eventdata, handles)

if get(handles.ACOTAR,'value') == 1
    set(handles.freq_min,'enable','on');
    set(handles.freq_max,'enable','on');
    set(handles.freq_min,'string','');
    set(handles.freq_max,'string','');
else
    set(handles.freq_min, 'String', 'Frec. min.');
    set(handles.freq_max, 'String', 'Frec. max.');
    set(handles.freq_min,'enable','off');
    set(handles.freq_max,'enable','off');
end


%% SECCION MENUES

%% octavas

function menu_31hz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_31hz_oct,'Checked','on')
data.xHz = 31.5;
data.nrobanda = 1;
guidata(hObject,data)
p.graficos(data,handles)

function menu_63hz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_63hz_oct,'Checked','on')
data.xHz = 63;
data.nrobanda = 2;
guidata(hObject,data)
p.graficos(data,handles)

function menu_125hz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_125hz_oct,'Checked','on')
data.xHz = 125;
data.nrobanda = 3;
guidata(hObject,data)
p.graficos(data,handles)

function menu_250hz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_250hz_oct,'Checked','on')
data.xHz = 250;
data.nrobanda = 4;
guidata(hObject,data)
p.graficos(data,handles)

function menu_500hz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_500hz_oct,'Checked','on')
data.xHz = 500;
data.nrobanda = 5;
guidata(hObject,data)
p.graficos(data,handles)

function menu_1khz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_1khz_oct,'Checked','on')
data.xHz = 1000;
data.nrobanda = 6;
guidata(hObject,data)
p.graficos(data,handles)

function menu_2khz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_2khz_oct,'Checked','on')
data.xHz = 2000;
data.nrobanda = 7;
guidata(hObject,data)
p.graficos(data,handles)

function menu_4khz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_4khz_oct,'Checked','on')
data.xHz = 4000;
data.nrobanda = 8;
guidata(hObject,data)
p.graficos(data,handles)

function menu_8khz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_8khz_oct,'Checked','on')
data.xHz = 8000;
data.nrobanda = 9;
guidata(hObject,data)
p.graficos(data,handles)

function menu_16khz_oct_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_16khz_oct,'Checked','on')
data.xHz = 16000;
data.nrobanda = 10;
guidata(hObject,data)
p.graficos(data,handles)

%% Full Band

function menu_full_band_Callback(hObject, eventdata, handles)
data = guidata(hObject);
p = parameters;
p.menuchecks(handles)
set(handles.menu_full_band,'Checked','on')
data.xHz = 0;
data.nrobanda = 11;
guidata(hObject,data)
p.graficos(data,handles)

%% OTROS

function freq_min_Callback(hObject, eventdata, handles)

function freq_min_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function freq_max_Callback(hObject, eventdata, handles)

function freq_max_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
