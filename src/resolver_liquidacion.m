function resultado = resolver_liquidacion(gastos, usarLimite, K)
% RESOLVER_LIQUIDACION
% Resuelve una instancia del problema de liquidacion de gastos.


    % Asegurar formato fila
    gastos = gastos(:)';
    
    
    % Validacion basica (nargin number of inputs)
    if nargin < 2
        usarLimite = false;
    end
    if nargin < 3
        K = NaN;
    end

  %Procesado de datos
    nump = length(gastos);
    total = sum(gastos);

    parte_base = floor(total / nump);
    resto = mod(total, nump);

    reparto = parte_base * ones(1, nump);
    reparto(1:resto) = reparto(1:resto) + 1;

    saldo = gastos - reparto;

    D = find(saldo < 0);
    C = find(saldo > 0);

    d = -saldo(D);
    c = saldo(C);

    nd = length(d);
    nc = length(c);

    % ya todo esta saldado
    if nd == 0 && nc == 0
        resultado.nump = nump;
        resultado.total = total;
        resultado.gastos = gastos;
        resultado.reparto = reparto;
        resultado.saldo = saldo;
        resultado.D = D;
        resultado.C = C;
        resultado.d = d;
        resultado.c = c;
        resultado.nd = nd;
        resultado.nc = nc;
        resultado.usarLimite = usarLimite;
        resultado.K = K;
        resultado.factible = true;
        resultado.status = 'Todo saldado';
        resultado.objval = 0;
        resultado.runtime = 0;
        resultado.numTransferencias = 0;
        resultado.maxTransDeudor = 0;
        resultado.x_sol = [];
        resultado.y_sol = [];
        resultado.tabla_transferencias = table([], [], [], ...
            'VariableNames', {'Deudor','Acreedor','Importe'});
        return;
    end

    %Definicion de variables
    nX = nd * nc;
    nY = nd * nc;
    nVar = nX + nY;

    var_x = 1:nX;
    var_y = nX + (1:nY);

    obj = [zeros(nX,1); ones(nY,1)];
    lb = zeros(nVar,1);
    ub = [inf(nX,1); ones(nY,1)];

    % Mantienes x enteras y y binarias
    ctype = [repmat('I',1,nX), repmat('B',1,nY)];
    sense = 'minimize';

    % Matrices de restricciones
    A1 = zeros(nd, nVar);
    A2 = zeros(nc, nVar);
    A3 = zeros(nY, nVar);

    if usarLimite
        A4 = zeros(nd, nVar);
    end

    % A1: cada deudor paga exactamente lo que debe
    fila = 1;
    inicio = 1;
    for i = nc:nc:nX
        A1(fila, inicio:i) = ones(1, nc);
        fila = fila + 1;
        inicio = i + 1;
    end

    lhs1 = d(:);
    rhs1 = d(:);

    % A2: cada acreedor recibe exactamente lo que le corresponde
    for j = 1:nc
        for i = 1:nd
            pos = (i-1)*nc + j;
            A2(j, pos) = 1;
        end
    end

    lhs2 = c(:);
    rhs2 = c(:);

    % A3: enlace x_ij <= M_ij * y_ij
    k = 1;
    z = 1;
    for i = 1:nY
        A3(i, i) = 1;
        A3(i, var_y(i)) = -min(d(k), c(z));

        if z == nc
            k = k + 1;
            z = 0;
        end
        z = z + 1;
    end

    lhs3 = -inf(nY,1);
    rhs3 = zeros(nY,1);

    % A4: maximo numero de transferencias por deudor
    if usarLimite
        for i = 1:nd
            for j = 1:nc
                pos = (i-1)*nc + j;
                A4(i, var_y(pos)) = 1;
            end
        end

        lhs4 = zeros(nd,1);
        rhs4 = K * ones(nd,1);

        A = [A1; A2; A3; A4];
        lhs = [lhs1; lhs2; lhs3; lhs4];
        rhs = [rhs1; rhs2; rhs3; rhs4];
    else
        A = [A1; A2; A3];
        lhs = [lhs1; lhs2; lhs3];
        rhs = [rhs1; rhs2; rhs3];
    end

   %Resolver Cplex
    addpath('C:\Program Files\IBM\ILOG\CPLEX_Enterprise_Server1210\CPLEX_Studio\cplex\matlab\x64_win64')

    cplex = Cplex('Liquidacion_Gastos');
    cplex.Model.sense = sense;
    cplex.Model.obj   = obj;
    cplex.Model.lb    = lb;
    cplex.Model.ub    = ub;
    cplex.Model.ctype = ctype;
    cplex.Model.A     = A;
    cplex.Model.lhs   = lhs;
    cplex.Model.rhs   = rhs;


   
t0 = tic;

try
    cplex.solve();
    runtime = toc(t0);

    sol = cplex.Solution.x;

    if isempty(sol)
        resultado = resultado_error(gastos, reparto, saldo, D, C, d, c, ...
            nump, total, nd, nc, usarLimite, K, runtime, ...
            'Sin solucion recuperable');
        return;
    end

    x_sol = sol(var_x);
    y_sol = sol(var_y);

catch ME
    runtime = toc(t0);
    resultado = resultado_error(gastos, reparto, saldo, D, C, d, c, ...
        nump, total, nd, nc, usarLimite, K, runtime, ME.message);
    return;
end

    deudor = [];
    acreedor = [];
    importe = [];

    transf_por_deudor = zeros(nd,1);

    for i = 1:nd
        for j = 1:nc
            pos = (i-1)*nc + j;

            if x_sol(pos) > 1e-9
                deudor(end+1,1) = D(i);
                acreedor(end+1,1) = C(j);
                importe(end+1,1) = x_sol(pos);

                if y_sol(pos) > 0.5
                    transf_por_deudor(i) = transf_por_deudor(i) + 1;
                end
            end
        end
    end

    tabla_transferencias = table(deudor, acreedor, importe, ...
        'VariableNames', {'Deudor','Acreedor','Importe'});

    numTransferencias = sum(y_sol > 0.5);
    maxTransDeudor = max(transf_por_deudor);

    %SALIDA
    resultado.nump = nump;
    resultado.total = total;
    resultado.gastos = gastos;
    resultado.reparto = reparto;
    resultado.saldo = saldo;
    resultado.D = D;
    resultado.C = C;
    resultado.d = d;
    resultado.c = c;
    resultado.nd = nd;
    resultado.nc = nc;
    resultado.usarLimite = usarLimite;
    resultado.K = K;
    resultado.factible = true;

    resultado.status = cplex.Solution.statusstring;
    resultado.objval = cplex.Solution.objval;
    
    resultado.runtime = runtime;
    resultado.numTransferencias = numTransferencias;
    resultado.maxTransDeudor = maxTransDeudor;
    resultado.x_sol = x_sol;
    resultado.y_sol = y_sol;
    resultado.tabla_transferencias = tabla_transferencias;
end


function resultado = resultado_error(gastos, reparto, saldo, D, C, d, c, ...
    nump, total, nd, nc, usarLimite, K, runtime, mensaje)

    resultado.nump = nump;
    resultado.total = total;
    resultado.gastos = gastos;
    resultado.reparto = reparto;
    resultado.saldo = saldo;
    resultado.D = D;
    resultado.C = C;
    resultado.d = d;
    resultado.c = c;
    resultado.nd = nd;
    resultado.nc = nc;
    resultado.usarLimite = usarLimite;
    resultado.K = K;
    resultado.factible = false;
    resultado.status = mensaje;
    resultado.objval = NaN;
    resultado.runtime = runtime;
    resultado.numTransferencias = NaN;
    resultado.maxTransDeudor = NaN;
    resultado.x_sol = [];
    resultado.y_sol = [];
    resultado.tabla_transferencias = table([], [], [], ...
        'VariableNames', {'Deudor','Acreedor','Importe'});
end