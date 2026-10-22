%Numero de personas
usarToyExample = false;

if usarToyExample
    gastos = [45 5 15 35 0 20];
else
    rng(1); % para que el ejemplo aleatorio sea reproducible
    nump = 10;
    gastos = randi([1,10000],1,nump);
end

nump = length(gastos);


total=sum(gastos);

%Cuanto le corresponde pagar a cada persona?
parte_base=floor(total/nump);
resto=mod(total,nump);

%Las primeras personas pagan un centavo mas
reparto = parte_base * ones(1,nump);
reparto(1:resto) = reparto(1:resto) + 1;

%Calculo de balances
saldo = gastos - reparto;
%Deudores y acreedores

D = find(saldo < 0);
C = find(saldo > 0);

%Cuanto debe cada uno?
d=-saldo(D);
c = saldo(C);

%Estructura del problema
disp('Cuota:');
disp(parte_base);

disp('Gastos:');
disp(gastos);

disp('Saldo:');
disp(saldo);

disp('Deudores D:');
disp(D);

disp('Acreedores C:');
disp(C);

disp('d:');
disp(d);

disp('c:');
disp(c);
%Cuantos hay en total
nd=length(d);
nc=length(c);

%maximo numero de transferencias que puede hacer cada deudor
K = 2;   

%Definicion de variables

nX=nd*nc;
nY=nd*nc;
nVar=nY+nX;

%Para definir las posiciones de Xij e Yij

var_x = 1:nX;
var_y = nX + (1:nY);

%Definicion variables cplex

obj=[ zeros(nX,1); ones(nY,1)];
lb = zeros(nVar,1);
ub = [inf(nX,1); ones(nY,1)];
ctype = [repmat('I',1,nX), repmat('B',1,nY)];
sense = 'minimize';

%Matriz de restricciones
A1=zeros(nd,nVar);
A2=zeros(nc,nVar);
A3=zeros(nY,nVar);
A4=zeros(nd,nVar);

%A1
fila=1;
inicio=1;
for i=nc:nc:nX
    A1(fila, inicio:i)=ones(1,nc);
    fila=fila+1;
    inicio=i+1;
end

lhs1=d(:);
rhs1=d(:);

%A2 (i -> D, j ->C)

for j=1:1:nc
  for i=1:1:nd
      
      pos = (i-1)*nc + j;
      
      A2(j , pos)=1;
      
  end
end

lhs2=c(:);
rhs2=c(:);

%A3

k=1;
z=1;
for i=1:nY
    
    A3(i,i)=1;
    A3(i,var_y(i))=-min(d(k),c(z));
    if z==nc
        
        k=k+1;
        z=0;
            
    end
    z=z+1;
end

lhs3=-inf(nX,1);
rhs3=zeros(nY,1);


%A4  maximo numero de transferencias por deudor

for i = 1:nd
    for j = 1:nc
        pos = (i-1)*nc + j;
        A4(i, var_y(pos)) = 1;
    end
end

lhs4 = -inf(nd,1);
rhs4 = K*ones(nd,1);

%
A=[A1;A2;A3;A4];
lhs=[lhs1;lhs2;lhs3;lhs4];
rhs=[rhs1;rhs2;rhs3;rhs4];

%Cplex tecnun
%addpath('C:\Program Files\IBM\ILOG\CPLEX_Studio1210\cplex\matlab\x64_win64')
%cplex = Cplex('Liquidacion_Gastos');


%Cplex casa
addpath('C:\Program Files\IBM\ILOG\CPLEX_Enterprise_Server1210\CPLEX_Studio\cplex\matlab\x64_win64')
cplex = Cplex('Liquidacion_Gastos');

cplex.Model.sense = sense;
cplex.Model.obj   = obj;
cplex.Model.lb    = lb;
cplex.Model.ub    = ub;
cplex.Model.ctype = ctype;

cplex.Model.A   = A;
cplex.Model.lhs = lhs;
cplex.Model.rhs = rhs;

cplex.solve();
sol = cplex.Solution.x;

x_sol = sol(var_x);
y_sol = sol(var_y);

%Mostrar Transferencias

deudor = [];
acreedor = [];
importe = [];

for i = 1:nd
    for j = 1:nc
        pos = (i-1)*nc + j;
        
        if x_sol(pos) > 0
            deudor(end+1,1) = D(i);
            acreedor(end+1,1) = C(j);
            importe(end+1,1) = x_sol(pos);
        end
    end
end

tabla_transferencias = table(deudor, acreedor, importe, ...
    'VariableNames', {'Deudor','Acreedor','Importe'});
tabla_transferencias.Importe = tabla_transferencias.Importe / 100;
disp(tabla_transferencias);
