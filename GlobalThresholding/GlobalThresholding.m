%% SCRIPT PRINCIPAL: LIMIARIZACAO GLOBAL ITERATIVA
clc;
clear;
close all;

% Definicao do arquivo alvo para o experimento
filename = 'rice-shaded.tif';

% Verificacao de consistencia do arquivo em disco
if exist(filename, 'file')
    f = imread(filename);
else
    error('Arquivo %s nao encontrado no diretorio corrente.', filename);
end

% Conversao para escala de cinza caso possua multiplos canais
if size(f, 3) > 1
    f = rgb2gray(f);
end

%% EXERCICIO (b): PROCESSAMENTO COM PARAMETRO DEFAULT (delT = 0.01)
delT_default = 0.01;
[g_default, T_final_default] = globalThresh(f, delT_default);
fprintf('Limiar final obtido (delT = 0.01): %.4f\n', T_final_default);

%% EXERCICIO (c): COMPARAÇÃO COM OUTROS VALORES DE TOLERANCIA (delT)
% Teste com valores alternativos para avaliar impacto na convergencia
delT_alt1 = 0.0001; % Criterio de convergencia extremamente rígido
delT_alt2 = 0.1;    % Criterio de convergencia frouxo

[g_alt1, T_final_alt1] = globalThresh(f, delT_alt1);
[g_alt2, T_final_alt2] = globalThresh(f, delT_alt2);

fprintf('Limiar final obtido (delT = 0.0001): %.4f\n', T_final_alt1);
fprintf('Limiar final obtido (delT = 0.1)   : %.4f\n', T_final_alt2);

%% APRESENTACAO VISUAL DOS RESULTADOS DOS EXPERIMENTOS
figure('Name', 'Analise de Limiarizacao Global Iterativa', 'NumberTitle', 'off');

% Painel 1: Imagem Original com sombreamento
subplot(2,2,1);
imshow(f);
title('Imagem Original (rice-shaded.tif)');

% Painel 2: Resultado com delT = 0.01
subplot(2,2,2);
imshow(g_default);
title(sprintf('Global (delT = 0.01) | T = %.2f', T_final_default));

% Painel 3: Resultado com delT = 0.0001
subplot(2,2,3);
imshow(g_alt1);
title(sprintf('Global (delT = 0.0001) | T = %.2f', T_final_alt1));

% Painel 4: Resultado com delT = 0.1
subplot(2,2,4);
imshow(g_alt2);
title(sprintf('Global (delT = 0.1) | T = %.2f', T_final_alt2));

%% =========================================================================
%% FUNCAO LOCAL: ALGORITMO ITERATIVO DE LIMIARIZACAO GLOBAL
%% =========================================================================

function [g, T] = globalThresh(f, detT)
    % GLOBALTHRESH Executa a segmentacao iterativa por limiar global.
    %   [g, T] = globalThresh(f, detT) escalona a imagem f para [0,1],
    %   calcula recursivamente o limiar otimo T baseado nas medias de 
    %   intensidade das classes e retorna a matriz binaria g.
    
    if nargin < 2
        detT = 0.01; % Atribuicao da tolerancia default
    end
    
    % Normalizacao automatica da matriz de entrada para o intervalo [0, 1]
    f_norm = double(f) / double(max(f(:)));
    
    % Inicializacao do estimador de limiar T como a media global de intensidade
    T = mean(f_norm(:));
    
    done = false;
    while ~done
        % Segmentacao logica em dois grupos baseados no limiar corrente
        g1 = f_norm > T;
        g2 = ~g1;
        
        % Tratamento de excecao para evitar divisao por zero em matrizes vazias
        if ~any(g1(:)) || ~any(g2(:))
            break;
        end
        
        % Calculo das medias de intensidade amostrais de cada regiao
        mu1 = mean(f_norm(g1));
        mu2 = mean(f_norm(g2));
        
        % Atualizacao linear do limiar
        T_next = 0.5 * (mu1 + mu2);
        
        % Verificacao do criterio de parada absoluto por tolerancia delT
        if abs(T - T_next) < detT
            done = true;
        end
        
        T = T_next;
    end
    
    % Geracao da imagem binaria de saída final baseada no limiar convergido
    g = f_norm > T;
end