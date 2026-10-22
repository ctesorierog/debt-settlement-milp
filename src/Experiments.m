clear; clc;

nump_list = [6 8 10 12 14 16 17];
semillas = 1:5;
K_list = [2 3];



Resultados = table();

for n = nump_list
    for s = semillas
        
        rng(s);
        gastos = randi([1,10000],1,n);

        resultado = resolver_liquidacion(gastos, false, NaN);

        fila = struct2table(resultado, 'AsArray', true);

        fila.gastos = [];
        fila.reparto = [];
        fila.saldo = [];
        fila.D = [];
        fila.C = [];
        fila.d = [];
        fila.c = [];
        fila.x_sol = [];
        fila.y_sol = [];
        fila.tabla_transferencias = [];

        fila.n = n;
        fila.semilla = s;
        fila.modelo = "base";

        Resultados = [Resultados; fila];
    end
end

for n = nump_list
    for s = semillas
        
        rng(s);
        gastos = randi([1,10000],1,n);

        for K = K_list
            
            resultado = resolver_liquidacion(gastos, true, K);

            fila = struct2table(resultado, 'AsArray', true);

            fila.gastos = [];
            fila.reparto = [];
            fila.saldo = [];
            fila.D = [];
            fila.C = [];
            fila.d = [];
            fila.c = [];
            fila.x_sol = [];
            fila.y_sol = [];
            fila.tabla_transferencias = [];

            fila.n = n;
            fila.semilla = s;
            fila.modelo = "limite";

            Resultados = [Resultados; fila];
        end
    end
end

disp(Resultados);

writetable(Resultados, 'resultados_bateria.csv');
save('resultados_bateria.mat', 'Resultados');