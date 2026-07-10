%% SCRIPT PRINCIPAL: FILTRAGEM NO DOMINIO DA FREQUENCIA E ALTA ENFASE
clc;
clear;
close all;

%% =========================================================================
%% PARTE (a): FILTRAGEM BUTTERWORTH NA IMAGEM WOMAN.TIF
%% =========================================================================
file_woman = 'woman.tif';
if exist(file_woman, 'file')
    f_woman = imread(file_woman);
else
    warning('Arquivo %s nao encontrado. Pulando etapa (a).', file_woman);
    f_woman = [];
end

if ~isempty(f_woman)
    if size(f_woman, 3) > 1, f_woman = rgb2gray(f_woman); end
    [M, N] = size(f_woman);
    
    % Frequencia de corte de projeto (D0) e Ordem do filtro (n)
    D0 = 0.05 * min(M, N); 
    n_order = 2;
    
    % Geracao das malhas de coordenadas espaciais centralizadas
    u = 0:(M-1); v = 0:(N-1);
    idx = find(u > M/2); u(idx) = u(idx) - M;
    idy = find(v > N/2); v(idy) = v(idy) - N;
    [V, U] = meshgrid(v, u);
    D = sqrt(U.^2 + V.^2);
    
    % Construcao dos filtros centrados para visualizacao 2D
    D_shift = fftshift(D);
    H_LP_shift = 1 ./ (1 + (D_shift ./ D0).^(2*n_order));
    H_HP_shift = 1 - H_LP_shift;
    
    % Filtros nao centralizados para multiplicacao direta na FFT
    H_LP = 1 ./ (1 + (D ./ D0).^(2*n_order));
    H_HP = 1 - H_LP;
    
    % Execucao da Transformada de Fourier e filtragem
    F_woman = fft2(double(f_woman));
    g_lp = real(ifft2(F_woman .* H_LP));
    g_hp = real(ifft2(F_woman .* H_HP));
    
    % Visualizacao dos Filtros apenas em 2D (Evita travar o navegador)
    figure('Name', 'Parte (a): Filtros Butterworth 2D', 'NumberTitle', 'off');
    subplot(1,2,1); imshow(H_LP_shift, []); title('Filtro Passa-Baixas 2D');
    subplot(1,2,2); imshow(H_HP_shift, []); title('Filtro Passa-Altas 2D');
    
    % Painel de resultados de imagens
    figure('Name', 'Parte (a): Resultados Filtragem - Imagem Woman', 'NumberTitle', 'off');
    subplot(1,3,1); imshow(f_woman); title('Original');
    subplot(1,3,2); imshow(uint8(mat2gray(g_lp)*255)); title('Passa-Baixas (Suavizada)');
    subplot(1,3,3); imshow(uint8(mat2gray(g_hp)*255)); title('Passa-Altas (Bordas)');
end

%% =========================================================================
%% PARTES (b) e (c): TESTE DE ALTA ENFASE COM CHESTXRAY.TIF
%% =========================================================================
file_xray = 'chestXray.tif';
if exist(file_xray, 'file')
    f_xray = imread(file_xray);
else
    error('Arquivo critico %s nao encontrado no diretorio corrente.', file_xray);
end

if size(f_xray, 3) > 1, f_xray = rgb2gray(f_xray); end

% Parametros de Alta Enfase: a=offset, b=multiplicador, type='butterworth', show=true
a_param = 0.5; 
b_param = 2.0; 
type_filt = 'butterworth';
show_boolean = true;

% Execucao da funcao requisitada
[H_HFE, g_filtered] = highEmphasisFilt(a_param, b_param, f_xray, type_filt, show_boolean);

% Computacao dos espectros de magnitude antes e depois (Escala Logaritmica)
F_before = fftshift(log(1 + abs(fft2(double(f_xray)))));
F_after  = fftshift(log(1 + abs(fft2(double(g_filtered)))));

% Aplicacao da de equalizacao de histograma na imagem filtrada (Requisito c)
g_equalized = histeq(uint8(mat2gray(g_filtered)*255));

% Plotagem do painel comparativo do Exercicio (c)
figure('Name', 'Parte (c): Pipeline de Processamento - Raio-X', 'NumberTitle', 'off');
subplot(2,3,1); imshow(f_xray); title('1. Original');
subplot(2,3,4); imshow(F_before, []); title('2. Espectro Original');
subplot(2,3,2); imshow(uint8(mat2gray(g_filtered)*255)); title('3. Filtrada Alta Enfase');
subplot(2,3,5); imshow(F_after, []); title('4. Espectro Filtrado');
subplot(2,3,3); imshow(g_equalized); title('5. Filtrada + Equalizada');

%% =========================================================================
%% FUNCOES LOCAIS
%% =========================================================================

function [H_HFE, g] = highEmphasisFilt(a, b, f, type, show)
    [M, N] = size(f);
    
    % Frequencia de corte fixa de projeto (D0) para o casamento de grades
    D0 = 0.05 * min(M, N);
    n_order = 2;
    
    % Geracao de malha de coordenadas de frequencia nao centralizada
    u = 0:(M-1); v = 0:(N-1);
    idx = find(u > M/2); u(idx) = u(idx) - M;
    idy = find(v > N/2); v(idy) = v(idy) - N;
    [V, U] = meshgrid(v, u);
    D = sqrt(U.^2 + V.^2);
    
    % Selecao da assinatura do filtro passa-altas de base (H_HP)
    switch lower(type)
        case 'butterworth'
            H_LP = 1 ./ (1 + (D ./ D0).^(2*n_order));
            H_HP = 1 - H_LP;
        case 'gaussian'
            H_HP = 1 - exp(-(D.^2) / (2 * (D0^2)));
        case 'ideal'
            H_HP = double(D > D0);
        otherwise
            error('Tipo de filtro desconhecido. Use ''butterworth'', ''gaussian'' ou ''ideal''.');
    end
    
    % Sintese da equacao linear do Filtro de Alta Enfase
    H_HFE = a + b * H_HP;
    
    % Processamento espectral via multiplicacao direta de matrizes complexas
    F = fft2(double(f));
    g = real(ifft2(F .* H_HFE));
    
    % Plotagem condicional controlada pelo parametro show apenas em 2D
    if islogical(show) && show
        H_shift = fftshift(H_HFE);
        figure('Name', 'Parte (b): Filtro High-Emphasis 2D', 'NumberTitle', 'off');
        imshow(H_shift, []); title('Filtro HFE 2D');
    end
end