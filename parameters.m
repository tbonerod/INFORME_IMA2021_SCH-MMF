function [p] = parameters
p.regression = @regresionlineal;
p.regressionlimits = @regressionlimits;
p.graficos  = @graficos;
p.menuchecks = @menuchecks;
p.botonactivar = @botonactivar;
end

function [x0,x5,x10,x25,x35] = regressionlimits(y)

    x0=find(y<=0,1);      %Busco el pico para EDT
    x5=find(y<=-5,1);     %Busco la caida de 5dB para T20 y T30
    x10=find(y<=-10,1);   %Busco la caida de 10dB para EDT
    x25=find(y<=-25,1);   %Busco la caida de 25dB para T20
    x35=find(y<=-35,1);   %Busco la caida de 35dB para T30

end

function  [a, b, r2] = regresionlineal(x,y)
% Outputs de la funcion son Y = aX+b

n=length(x);
%Pendiente de la recta de regresion, a
a =(n*sum(x.*y)-sum(x)*sum(y))/(n*sum(x.^2)-sum(x)*sum(x)); 
%Ordenada al origen, b
b =(sum(y)-a*sum(x))/n;
%Calculo del coeficiente de correlacion r
SX2 = sum(x.^2); 
SY2 = sum(y.^2); 
SXY = sum(x.*y);
r = (n*SXY - sum(x).*sum(y)) / (sqrt((n*SX2 - ((sum(x)^2)))*(n*SY2 - (sum(y)^2))));
r2 = r^2;
end

function graficos(data,handles)

nrobanda = data.nrobanda;
banda = data.dBxtot(nrobanda,:);

%% Cargar la data en la tabla de la GUI

data.parametros = [data.tabla.TOT.edt,data.tabla.TOT.t20,data.tabla.TOT.t30];

data.parametros = num2cell(data.parametros);
index = find([data.parametros{:}] == 0);
data.parametros(index) = {'-'};

set(handles.tablaparametros,'Data',data.parametros)
Aedt = data.regresiones.TOT.Aedt(nrobanda);
Bedt = data.regresiones.TOT.Bedt(nrobanda);
At20 = data.regresiones.TOT.At20(nrobanda);
Bt20 = data.regresiones.TOT.Bt20(nrobanda);
At30 = data.regresiones.TOT.At30(nrobanda);
Bt30 = data.regresiones.TOT.Bt30(nrobanda);
RF = data.RFtot(nrobanda);
suavecito = data.SUAVtot(nrobanda,:);

%% Ploteo en la GUI

n=length(banda);
T=n/data.FS;
t=linspace(0,T,data.FS*T);
yedt = Aedt*t*data.FS + Bedt;
yt20 = At20*t*data.FS + Bt20;
yt30 = At30*t*data.FS + Bt30;
yRF = ones(1,round(T*data.FS))*RF;
cla
 
plot(t,banda(1:length(t)));hold on;...
plot(t,suavecito(1:length(t)),...
t,yRF(1:length(t)),...
t,yedt(1:length(t)), ...
t,yt20(1:length(t)),...
t,yt30(1:length(t)),...
'LineWidth',2);

if data.xHz == 0
    txt = ('CURVAS DE DECAIMIENTO. Banda Completa');
else
    txt = ['CURVAS DE DECAIMIENTO. Banda: ' num2str(data.xHz) ' Hz'];
end
title(txt);
xlabel('Tiempo [s]'); ylabel('Curvas de decaimiento normalizadas [dB]');
if get(handles.boton_sch, 'Value') > get(handles.boton_MM, 'Value')
    nombreSuav = 'Suavizado Schoeder';
else
    nombreSuav = 'Suavizado Mediana Movil';
end
legend({'Curva de decaimiento - envolvente',nombreSuav,'Ruido de fondo estimado',...
    'Regresion EDT','Regresion T20','Regresion T30'},'FontSize',12); grid on; grid minor;
legend('boxoff')
set(handles.grafico,'Color',[0.97,0.97,0.97])
ylim([RF-20 6]);
end

function menuchecks(handles)
% octavas
set(handles.menu_31hz_oct,'Checked','off')
set(handles.menu_63hz_oct,'Checked','off')
set(handles.menu_125hz_oct,'Checked','off')
set(handles.menu_250hz_oct,'Checked','off')
set(handles.menu_500hz_oct,'Checked','off')
set(handles.menu_1khz_oct,'Checked','off')
set(handles.menu_2khz_oct,'Checked','off')
set(handles.menu_4khz_oct,'Checked','off')
set(handles.menu_8khz_oct,'Checked','off')
set(handles.menu_16khz_oct,'Checked','off')
% Full banda
set(handles.menu_full_band,'Checked','off')
end
