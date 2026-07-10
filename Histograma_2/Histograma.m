clc;
clear;
close all;

% Definição dos nomes das imagens de teste 
image_files = {'rose1024.tif', 'spillway-dark.tif', 'hidden-horse.tif'};

% Loop de processamento para cada imagem do conjunto de teste
for i = 1:length(image_files)
    filename = image_files{i};
    
    % Verificação de existência do arquivo antes da leitura
    if exist(filename, 'file') ~= 2
        warning('Arquivo %s não encontrado no diretório atual.', filename);
        continue;
    end
    
    % Leitura da imagem de entrada (escala de cinza de 8 bits)
    f = imread(filename);
    if size(f, 3) > 1
        f = rgb2gray(f); % Conversão para escala de cinza caso seja RGB
    end
    
    % i. Computação do histograma normalizado (modo padrão 'n')
    hist_norm = imagehist4e(f, 'n');
    
    % ii. Execução do algoritmo de equalização de histograma
    g = histEqual4e(f);
    
    % Computação do histograma da imagem equalizada para análise de resultados
    hist_eq = imagehist4e(g, 'n');
    
    % iii. Visualização dos resultados (Imagem Original, Equalizada e seus Histogramas)
    figure('Name', ['Resultados: ' filename], 'NumberTitle', 'off');
    
    % Subplot 1: Imagem Original
    subplot(2, 2, 1);
    imshow(f);
    title('Imagem Original');
    
    % Subplot 2: Histograma da Imagem Original
    subplot(2, 2, 2);
    stem(0:255, hist_norm, 'Marker', 'none');
    xlim([0 255]);
    grid on;
    title('Histograma Original (Normalizado)');
    xlabel('Nível de Intensidade');
    ylabel('Frequência Relativa');
    
    % Subplot 3: Imagem Equalizada
    subplot(2, 2, 3);
    imshow(g);
    title('Imagem Equalizada');
    
    % Subplot 4: Histograma da Imagem Equalizada
    subplot(2, 2, 4);
    stem(0:255, hist_eq, 'Marker', 'none');
    xlim([0 255]);
    grid on;
    title('Histograma Equalizado');
    xlabel('Nível de Intensidade');
    ylabel('Frequência Relativa');
end

%% i. Função para Cálculo de Histograma de Imagem de 256 Níveis
function g = imagehist4e(f, mode)
    % Define 'n' como modo padrão caso não seja fornecido
    if nargin < 2
        mode = 'n';
    end
    
    % Inicialização do vetor do histograma com zeros para os 256 níveis
    g = zeros(256, 1);
    [rows, cols] = size(f);
    
    % Conversão explícita para uint8 para garantir indexação correta
    f_uint8 = uint8(f);
    
    % Contagem de ocorrência de cada nível de intensidade
    for r = 1:rows
        for c = 1:cols
            intensity = f_uint8(r, c);
            g(intensity + 1) = g(intensity + 1) + 1; % Indexação base-1 do MATLAB
        end
    end
    
    % Aplicação de normalização caso o parâmetro mode seja 'n'
    if mode == 'n'
        total_pixels = rows * cols;
        g = g / total_pixels;
    end
end

%% ii. Função para Equalização de Histograma (8 bits)
function g = histEqual4e(f)
    [rows, cols] = size(f);
    total_pixels = rows * cols;
    
    % Obtenção do histograma normalizado da imagem de entrada
    pr = imagehist4e(f, 'n');
    
    % Cálculo da Função de Distribuição Acumulada (CDF)
    sk = zeros(256, 1);
    sum_pr = 0;
    for k = 1:256
        sum_pr = sum_pr + pr(k);
        sk(k) = sum_pr;
    end
    
    % Mapeamento dos novos níveis de intensidade e arredondamento para L=256
    sk_scaled = round(sk * 255);
    
    % Inicialização da matriz da imagem de saída
    g = zeros(rows, cols, 'uint8');
    f_uint8 = uint8(f);
    
    % Transformação dos pixels da imagem original com base no mapa calculado
    for r = 1:rows
        for c = 1:cols
            orig_intensity = f_uint8(r, c);
            g(r, c) = sk_scaled(orig_intensity + 1);
        end
    end
end