%% SCRIPT PRINCIPAL: PROCESSAMENTO MORFOLOGICO DE IMAGENS BINARIAS
clc;
clear;
close all;

% Definicao do arquivo de entrada conforme
input_file = 'FigP0918(left) (1).tif';

% Verificacao de existencia do arquivo e leitura de dados
if exist(input_file, 'file')
    A = imread(input_file);
else
    error('Arquivo %s nao encontrado no diretorio de trabalho.', input_file);
end

% Binarizacao forcada da imagem de entrada (limiarizacao logica)
if ~islogical(A)
    A = A > 127; 
end

%% CONFIGURACAO DO ELEMENTO ESTRUTURANTE (SE)
% Elemento estruturante quadrado de dimensoes 13x13 para eliminacao de 
% estruturas de tamanho inferior ou igual a 13 pixels.
se_size = 13;
B = ones(se_size, se_size);

%% EXECUCAO DO FILTRAGEM MORFOLOGICA (ABERTURA)
% Etapa 1: Erosao para supressao de objetos menores que o SE
img_eroded = mm_erode(A, B);

% Etapa 2: Dilatacao para recomposicao geometrica dos objetos remanescentes
img_opened = mm_dilate(img_eroded, B);

%% APRESENTACAO E PLOTAGEM DOS RESULTADOS
figure('Name', 'Projeto de Morfologia Matematica Binaria', 'NumberTitle', 'off');

% Subplot 1: Imagem Original Binaria
subplot(1,3,1);
imshow(A);
title('A. Imagem Original');

% Subplot 2: Resultado apos Erosao Discreta
subplot(1,3,2);
imshow(img_eroded);
title('B. Resultado da Erosao (SE 13x13)');

% Subplot 3: Resultado Final (Abertura Concluida)
subplot(1,3,3);
imshow(img_opened);
title('C. Resultado Final (Abertura)');

%% =========================================================================
%% FUNCOES LOCAIS DE MORFOLOGIA MATEMATICA (PADDING DE ZEROS DEFAULT)
%% =========================================================================

function G = mm_erode(A, B)
    % MM_ERODE Executa a erosao morfologica de uma imagem binaria A pelo SE B.
    %   G = mm_erode(A, B) computa o mapeamento de minimos locais (intersecao estrita).
    
    [h_A, w_A] = size(A);
    [h_B, w_B] = size(B);
    
    % Calculo dos raios de extensao espacial do elemento estruturante
    r_h = floor(h_B / 2);
    r_w = floor(w_B / 2);
    
    % Inicializacao da matriz de saida com zeros
    G = false(h_A, w_A);
    
    % Criacao da matriz com padding de zeros (borda nula default)
    A_padded = false(h_A + 2*r_h, w_A + 2*r_w);
    A_padded(r_h+1:r_h+h_A, r_w+1:r_w+w_A) = A;
    
    % Otimizacao dos indices logicos do elemento estruturante ativos
    linear_B = find(B == 1);
    num_elements_B = length(linear_B);
    
    % Varredura espacial e checagem de condicao de ajuste total (Fit)
    for r = 1:h_A
        for c = 1:w_A
            % Extracao da submatriz sob a vizinhanca corrente do SE
            sub_matrix = A_padded(r:r+h_B-1, c:c+w_B-1);
            
            % Verificacao se todos os pixels ativos de B encontram correspondencia em A
            if sum(sub_matrix(linear_B)) == num_elements_B
                G(r, c) = true;
            end
        end
    end
end

function G = mm_dilate(A, B)
    % MM_DILATE Executa a dilatacao morfologica de uma imagem binaria A pelo SE B.
    %   G = mm_dilate(A, B) computa o mapeamento de maximos locais (intersecao parcial).
    
    [h_A, w_A] = size(A);
    [h_B, w_B] = size(B);
    
    % Calculo dos raios de extensao espacial do elemento estruturante
    r_h = floor(h_B / 2);
    r_w = floor(w_B / 2);
    
    % Inicializacao da matriz de saida com zeros
    G = false(h_A, w_A);
    
    % Criacao da matriz com padding de zeros (borda nula default)
    A_padded = false(h_A + 2*r_h, w_A + 2*r_w);
    A_padded(r_h+1:r_h+h_A, r_w+1:r_w+w_A) = A;
    
    % Otimizacao dos indices logicos do elemento estruturante ativos
    linear_B = find(B == 1);
    
    % Varredura espacial e checagem de condicao de intersecao (Hit)
    for r = 1:h_A
        for c = 1:w_A
            % Extracao da submatriz sob a vizinhanca corrente do SE
            sub_matrix = A_padded(r:r+h_B-1, c:c+w_B-1);
            
            % Verificacao se existe ao menos uma colisao entre pixels ativos
            if any(sub_matrix(linear_B))
                G(r, c) = true;
            end
        end
    end
end