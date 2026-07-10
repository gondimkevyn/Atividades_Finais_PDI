%% SCRIPT PRINCIPAL: DATA AUGMENTATION E TRANSFORMACOES GEOMETRICAS
clc;
clear;
close all;

%% ETAPA 1: DEMONSTRACAO COM A IMAGEM (girl.tif)
target_single = 'girl.tif';

if exist(target_single, 'file')
    % Leitura e conversao forcada para tons de cinza
    f_girl = imread(target_single);
    if size(f_girl, 3) > 1
        f_girl = rgb2gray(f_girl);
    end
    
    % Execucao das transformacoes geometricas discretas
    g_resize    = imageResize(f_girl, 224, 224);
    g_trans_x   = imageTranslate(g_resize, 7, 0);
    g_trans_y   = imageTranslate(g_resize, 0, 10);
    g_zoom_105  = imageZoom(g_resize, 1.05, 1.05);
    g_zoom_110  = imageZoom(g_resize, 1.10, 1.10);
    g_reflect_y = imageReflection(g_resize, 'y');
    
    % Plotagem do painel comparativo de resultados
    figure('Name', 'Pipeline de Data Augmentation - girl.tif', 'NumberTitle', 'off');
    
    subplot(2,3,1); imshow(g_resize); title('1. Resized (224x224)');
    subplot(2,3,2); imshow(g_trans_x); title('2. Translate X (+7, 0)');
    subplot(2,3,3); imshow(g_trans_y); title('3. Translate Y (0, +10)');
    subplot(2,3,4); imshow(g_zoom_105); title('4. Zoom (1.05x)');
    subplot(2,3,5); imshow(g_zoom_110); title('5. Zoom (1.10x)');
    subplot(2,3,6); imshow(g_reflect_y); title('6. Reflection H (Mode Y)');
else
    warning('Arquivo de demonstracao %s nao encontrado no diretorio.', target_single);
end

%% ETAPA 2: PROCESSAMENTO DO DATASET COVID
covid_dir = 'Dataset/Covid'; % Caminho relativo padrao para o dataset

if exist(covid_dir, 'dir')
    % Filtragem de arquivos de imagem no diretorio alvo
    img_extensions = {'*.jpg', '*.jpeg', '*.png', '*.tif'};
    file_list = [];
    for ext = img_extensions
        file_list = [file_list; dir(fullfile(covid_dir, ext{1}))];
    end
    
    % Loop de iteracao sobre as amostras da classe Covid
    for i = 1:length(file_list)
        img_path = fullfile(covid_dir, file_list(i).name);
        [~, base_name, ext_name] = fileparts(file_list(i).name);
        
        f = imread(img_path);
        if size(f, 3) > 1
            f = rgb2gray(f);
        end
        
        % Redimensionamento obrigatorio para resolucao de entrada de rede (224x224)
        f_scaled = imageResize(f, 224, 224);
        
        % Geracao e salvamento das variantes geometricas requisitadas
        g1 = imageTranslate(f_scaled, 7, 0);
        imwrite(g1, fullfile(covid_dir, [base_name, '_xTranslate_7', ext_name]));
        
        g2 = imageTranslate(f_scaled, 0, 10);
        imwrite(g2, fullfile(covid_dir, [base_name, '_yTranslate_10', ext_name]));
        
        g3 = imageZoom(f_scaled, 1.05, 1.05);
        imwrite(g3, fullfile(covid_dir, [base_name, '_Zoom_1.05', ext_name]));
        
        g4 = imageZoom(f_scaled, 1.1, 1.1);
        imwrite(g4, fullfile(covid_dir, [base_name, '_Zoom_1.1', ext_name]));
        
        g5 = imageReflection(f_scaled, 'y');
        imwrite(g5, fullfile(covid_dir, [base_name, '_HorizontalReflection', ext_name]));
    end
    fprintf('Processamento de Data Augmentation concluido para %d imagens.\n', length(file_list));
else
    fprintf('Diretorio "%s" ausente. Etapa de dataset ignorada (Modo de contingencia ativo).\n', covid_dir);
end

%% =========================================================================
%% FUNCOES LOCAIS DE TRANSFORMACAO GEOMETRICA (INTERPOLACAO BILINEAR MANAL)
%% =========================================================================

function g = imageResize(f, numrows, numcols)
    % IMAGERESIZE Redimensiona imagem mantendo aspect ratio e preenchendo com branco.
    [H, W] = size(f);
    scale = min(numrows / H, numcols / W);
    new_H = round(H * scale);
    new_W = round(W * scale);
    
    % Interpolacao bilinear da regiao util dimensionada
    g_scaled = bilinearInterpolation(f, new_H, new_W);
    
    % Alocacao da matriz final preenchida com fundo branco (255)
    g = uint8(ones(numrows, numcols) * 255);
    
    % Centralizacao da imagem redimensionada dentro da matriz final
    row_start = floor((numrows - new_H) / 2) + 1;
    col_start = floor((numcols - new_W) / 2) + 1;
    g(row_start:row_start+new_H-1, col_start:col_start+new_W-1) = g_scaled;
end

function g = imageReflection(f, mode)
    % IMAGEREFLECTION Realiza reflexao geometrica matricial direta.
    if strcmp(mode, 'x')
        g = f(end:-1:1, :); % Inversao vertical do indexador de linhas
    elseif strcmp(mode, 'y')
        g = f(:, end:-1:1); % Inversao horizontal do indexador de colunas
    else
        error('Modo invalido. Utilize ''x'' ou ''y''.');
    end
end

function g = imageZoom(f, cx, cy)
    % IMAGEZOOM Aplica zoom por fator multiplicativo e realiza crop centralizado.
    [H, W] = size(f);
    new_H = round(H * cx);
    new_W = round(W * cy);
    
    % Expansao espacial via interpolacao bilinear
    g_zoomed = bilinearInterpolation(f, new_H, new_W);
    
    % Recorte simetrico para retorno ao tamanho geometrico original [H, W]
    r_start = floor((new_H - H) / 2) + 1;
    c_start = floor((new_W - W) / 2) + 1;
    
    % Tratamento de contorno para fatores de reducao de escala (se aplicavel)
    if r_start > 0 && c_start > 0
        g = g_zoomed(r_start:r_start+H-1, c_start:c_start+W-1);
    else
        g = uint8(ones(H, W) * 255);
        r_target = max(1, 2 - r_start);
        c_target = max(1, 2 - c_start);
        h_chunk = min(H, new_H);
        w_chunk = min(W, new_W);
        g(r_target:r_target+h_chunk-1, c_target:c_target+w_chunk-1) = g_zoomed(1:h_chunk, 1:w_chunk);
    end
end

function g = imageTranslate(f, tx, ty)
    % IMAGETRANSLATE Translada a matriz da imagem preenchendo vazios com branco.
    [H, W] = size(f);
    g = uint8(ones(H, W) * 255); % Inicializacao do background
    
    % Mapeamento inverso direto por deslocamento de indices lineares
    for r = 1:H
        orig_r = r - tx; % Deslocamento vertical x (linhas)
        for c = 1:W
            orig_c = c - ty; % Deslocamento horizontal y (colunas)
            
            % Verificacao de limites espaciais da matriz original
            if orig_r >= 1 && orig_r <= H && orig_c >= 1 && orig_c <= W
                g(r, c) = f(orig_r, orig_c);
            end
        end
    end
end

function g = bilinearInterpolation(f, new_H, new_W)
    % BILINEARINTERPOLATION Core do algoritmo de reconstrucao de intensidade continuada.
    [H, W] = size(f);
    f = double(f);
    g = zeros(new_H, new_W);
    
    % Geracao de mapeamento projetivo inverso
    for r = 1:new_H
        rf = ((r - 0.5) * (H / new_H)) + 0.5;
        r1 = max(1, floor(rf));
        r2 = min(H, ceil(rf));
        delta_r = rf - r1;
        
        for c = 1:new_W
            cf = ((c - 0.5) * (W / new_W)) + 0.5;
            c1 = max(1, floor(cf));
            c2 = min(W, ceil(cf));
            delta_c = cf - c1;
            
            % Interpolacao ponderada nos 4 vizinhos adjacentes
            v1 = f(r1, c1) * (1 - delta_c) + f(r1, c2) * delta_c;
            v2 = f(r2, c1) * (1 - delta_c) + f(r2, c2) * delta_c;
            g(r, c) = v1 * (1 - delta_r) + v2 * delta_r;
        end
    end
    g = uint8(g);
end