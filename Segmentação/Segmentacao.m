%% SCRIPT PRINCIPAL: EXTRACAO DE CONTORNOS DOS DOIS MAIORES BLOBS
clc;
clear;
close all;

% Definicao do vetor contendo os arquivos de imagem do experimento
image_files = {'Imagem1.jpg', 'Imagem2.jpg', 'Imagem3.jpg'};

for i = 1:length(image_files)
    img_name = image_files{i};
    
    % Verificacao de consistencia de leitura em disco
    if exist(img_name, 'file')
        f = imread(img_name);
    else
        warning('Arquivo %s nao encontrado no diretorio corrente.', img_name);
        continue;
    end
    
    % Conversao para escala de cinza de canal unico caso seja RGB
    if size(f, 3) > 1
        f = rgb2gray(f);
    end
    
    %% ETAPA 1: PRE-PROCESSAMENTO E BINARIZACAO ADAPTATIVA
    % Filtro de suavizacao por média móvel 5x5 para atenuacao de ruido espacial
    h_blur = ones(5,5) / 255;
    f_smoothed = conv2(double(f), h_blur, 'same');
    
    % Binarizacao baseada no perfil de vales de intensidade das estruturas
    % Os aneis escuros e centros estruturais sao mapeados por limiarizacao
    T_val = mean(f_smoothed(:)) * 0.92; 
    f_bin = f_smoothed < T_val;
    
    % Limpeza morfologica basica: remocao de particulas isoladas (ruido de borda)
    f_bin = mm_clean_artifacts(f_bin, 5);

    %% ETAPA 2: ANALISE DE COMPONENTES CONECTADOS E SELECAO POR AREA
    % Rotulacao manual das regioes conectadas em conectividade-4
    [L, num_labels] = manual_connected_components(f_bin);
    
    % Calculo vetorial das areas geométricas (contagem de pixels por rotulo)
    areas = zeros(1, num_labels);
    for label_idx = 1:num_labels
        areas(label_idx) = sum(L(:) == label_idx);
    end
    
    % Classificacao e ordenacao decrescente de magnitude de area
    [sorted_areas, sorted_indices] = sort(areas, 'descend');
    
    % Isolar estritamente as duas maiores regioes (indices 1 e 2 apos sort)
    g_largest_blobs = false(size(f_bin));
    if num_labels >= 1
        g_largest_blobs(L == sorted_indices(1)) = true;
    end
    if num_labels >= 2
        g_largest_blobs(L == sorted_indices(2)) = true;
    end
    
    %% ETAPA 3: EXTRACAO DAS FRONTEIRAS (BOUNDARIES)
    % Obtencao do contorno via diferenca morfologica (Gradiente Interno)
    % Subtrai do mapa binario a sua versao erodida por elemento estruturante 3x3
    se_edge = ones(3,3);
    g_eroded = manual_erosion(g_largest_blobs, se_edge);
    g_boundaries = g_largest_blobs & ~g_eroded;
    
    %% ETAPA 4: SOBREPOSICAO DO CONTORNO NA IMAGEM ORIGINAL PARA EXIBICAO
    img_display = f;
    % Atribuicao do brilho maximo (255) nas coordenadas do contorno para destaque
    img_display(g_boundaries) = 255;
    
    %% APRESENTACAO COMPOSITA DOS RESULTADOS
    figure('Name', ['Analise de Segmentacao: ' img_name], 'NumberTitle', 'off');
    
    subplot(1,3,1);
    imshow(f);
    title('Imagem Original');
    
    subplot(1,3,2);
    imshow(g_largest_blobs);
    title('Dois Maiores Blobs');
    
    subplot(1,3,3);
    imshow(img_display);
    title('Contornos Extraidos');
end

%% =========================================================================
%% FUNCOES LOCAIS DE PROCESSAMENTO MATRICIAL
%% =========================================================================

function [L, num_labels] = manual_connected_components(binary_matrix)
    % COMPONENTES CONECTADOS: Algoritmo Adaptado de Varredura de Duas Passadas
    [H, W] = size(binary_matrix);
    L = zeros(H, W);
    parent = 1:10000; % Vetor para gerenciamento de equivalencias de rotulos
    next_label = 1;
    
    % Passada 1: Atribuicao de rotulos provisorios e registro de equivalencias
    for r = 2:H-1
        for c = 2:W-1
            if binary_matrix(r, c)
                % Inspecao dos vizinhos causais (conectividade-4: Norte e Oeste)
                r_n = L(r-1, c);
                r_w = L(r, c-1);
                
                if r_n == 0 && r_w == 0
                    L(r, c) = next_label;
                    next_label = next_label + 1;
                elseif r_n ~= 0 && r_w == 0
                    L(r, c) = r_n;
                elseif r_n == 0 && r_w ~= 0
                    L(r, c) = r_w;
                else
                    L(r, c) = r_n;
                    % Registro de equivalencia na estrutura de uniao-busca
                    root_n = find_root(parent, r_n);
                    root_w = find_root(parent, r_w);
                    if root_n ~= root_w
                        parent(max(root_n, root_w)) = min(root_n, root_w);
                    end
                end
            end
        end
    end
    
    % Passada 2: Resolucao das equivalencias e mapeamento final contiguo
    unique_labels = zeros(1, next_label);
    actual_label_counter = 0;
    
    for r = 1:H
        for c = 1:W
            if L(r, c) > 0
                root = find_root(parent, L(r, c));
                if unique_labels(root) == 0
                    actual_label_counter = actual_label_counter + 1;
                    unique_labels(root) = actual_label_counter;
                end
                L(r, c) = unique_labels(root);
            end
        end
    end
    num_labels = actual_label_counter;
end

function root = find_root(parent, id)
    % Busca recursiva da raiz do rotulo equivalente
    root = id;
    while parent(root) ~= root
        root = parent(root);
    end
end

function g_clean = mm_clean_artifacts(f_bin, size_se)
    % Remove pequenas particulas ruidosas por erosao basica de vizinhanca
    se = ones(size_se, size_se);
    g_clean = manual_erosion(f_bin, se);
    % Dilatacao subsequente para restaurar escala util remanescente
    [h_A, w_A] = size(g_clean);
    g_dilated = false(h_A, w_A);
    r_h = floor(size_se / 2);
    for r = r_h+1:h_A-r_h
        for c = r_h+1:w_A-r_h
            if g_clean(r, c)
                g_dilated(r-r_h:r+r_h, c-r_h:c+r_h) = true;
            end
        end
    end
    g_clean = g_dilated & f_bin;
end

function G = manual_erosion(A, B)
    % Operador de erosao binaria por correspondencia estrita de vizinhanca
    [h_A, w_A] = size(A);
    [h_B, w_B] = size(B);
    r_h = floor(h_B / 2);
    r_w = floor(w_B / 2);
    G = false(h_A, w_A);
    linear_B = find(B == 1);
    num_elements_B = length(linear_B);
    
    for r = r_h+1:h_A-r_h
        for c = r_w+1:w_A-r_w
            sub_matrix = A(r-r_h:r+r_h, c-r_w:c+r_w);
            if sum(sub_matrix(linear_B)) == num_elements_B
                G(r, c) = true;
            end
        end
    end
end