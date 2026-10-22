clear; clc;

load('resultados_bateria.mat','Resultados');
T = Resultados;

% Quedarnos solo con corridas factibles
Tf = T(T.factible == 1, :);


% Tiempo medio de resolucion por tamaño y modelo
G1 = groupsummary(Tf, {'nump','modelo'}, 'mean', 'runtime');

figure;
hold on;

base = G1(G1.modelo == "base", :);
plot(base.nump, base.mean_runtime, '-o', 'LineWidth', 1.5);

limite = G1(G1.modelo == "limite", :);
plot(limite.nump, limite.mean_runtime, '-s', 'LineWidth', 1.5);

xlabel('Numero de personas');
ylabel('Tiempo medio de resolucion (s)');
title('Tiempo de resolucion vs numero de personas');
legend('Modelo base','Modelo con limite','Location','northwest');
grid on;

% Numero medio de transferencias por tamaño y modelo
G2 = groupsummary(Tf, {'nump','modelo'}, 'mean', 'numTransferencias');

figure;
hold on;

base = G2(G2.modelo == "base", :);
plot(base.nump, base.mean_numTransferencias, '-o', 'LineWidth', 1.5);

limite = G2(G2.modelo == "limite", :);
plot(limite.nump, limite.mean_numTransferencias, '-s', 'LineWidth', 1.5);

xlabel('Numero de personas');
ylabel('Numero medio de transferencias');
title('Transferencias vs numero de personas');
legend('Modelo base','Modelo con limite','Location','northwest');
grid on;

% Maximo medio de transferencias por deudor
G3 = groupsummary(Tf, {'nump','modelo'}, 'mean', 'maxTransDeudor');

figure;
hold on;

base = G3(G3.modelo == "base", :);
plot(base.nump, base.mean_maxTransDeudor, '-o', 'LineWidth', 1.5);

limite = G3(G3.modelo == "limite", :);
plot(limite.nump, limite.mean_maxTransDeudor, '-s', 'LineWidth', 1.5);

xlabel('Numero de personas');
ylabel('Media de maximo num de transferencias por deudor');
title('Maximo num de transferencias por deudor');
legend('Modelo base','Modelo con limite','Location','northwest');
grid on;

% Porcentaje de instancias factibles por tamaño, para K=2 y K=3
G4 = groupsummary(T, {'nump','modelo','K'}, 'mean', 'factible');
G4.porcentaje_factible = 100 * G4.mean_factible;

figure;
hold on;

K2 = G4(G4.modelo == "limite" & G4.K == 2, :);
plot(K2.nump, K2.porcentaje_factible, '-o', 'LineWidth', 1.5);

K3 = G4(G4.modelo == "limite" & G4.K == 3, :);
plot(K3.nump, K3.porcentaje_factible, '-s', 'LineWidth', 1.5);

xlabel('Numero de personas');
ylabel('Porcentaje de instancias factibles');
title('Factibilidad del modelo con limite');
legend('K = 2','K = 3','Location','southwest');
ylim([0 100]);
grid on;