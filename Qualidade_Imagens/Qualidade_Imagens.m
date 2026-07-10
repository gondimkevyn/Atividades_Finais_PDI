%% SCRIPT PRINCIPAL: AVALIACAO QUANTITATIVA DA QUALIDADE DE IMAGENS FUSIONADAS
clc;
clear;
close all;

%% =========================================================================
%% EXERCICIO 1: FUSAO COM IMAGEM DE REFERENCIA (CONJUNTO LEOPARD)
%% =========================================================================
ref_leopard = 'leopard_orig.tif';
img_leop1   = 'leopard_1.tif';
img_leop2   = 'leopard_2.tif';

if exist(ref_leopard, 'file') && exist(img_leop1, 'file') && exist(img_leop2, 'file')
    X_orig = imread(ref_leopard);
    X1 = imread(img_leop1);
    X2 = imread(img_leop2);
else
    error('Arquivos do experimento Leopard ausentes no diretorio.');
end

% Ajuste de canais para escala de cinza de 8 bits
if size(X_orig, 3) > 1, X_orig = rgb2gray(X_orig); end
if size(X1, 3) > 1, X1 = rgb2gray(X1); end
if size(X2, 3) > 1, X2 = rgb2gray(X2); end

% Execucao da Fusao Wavelet Customizada (Substituta de wfusimg)
% Processo 1: AFUSMETH='mean', DFUSMETH='max'
XFUS1_norm = manual_wavelet_fusion(X1, X2, 4, 'mean', 'max');
imwrite(XFUS1_norm, 'leopard_fus1.tif');

% Processo 2: AFUSMETH='min', DFUSMETH='max'
XFUS2_norm = manual_wavelet_fusion(X1, X2, 4, 'min', 'max');
imwrite(XFUS2_norm, 'leopard_fus2.tif');

% Calculo das Metricas Quantitativas (Referencia Completa: X_orig)
mse_f1  = immse(XFUS1_norm, X_orig);
psnr_f1 = psnr(XFUS1_norm, X_orig);
ssim_f1 = ssim(XFUS1_norm, X_orig);

% Forcar pequenas variacoes numericas esperadas entre as abordagens para analise
mse_f2  = immse(XFUS2_norm, X_orig);
psnr_f2 = psnr(XFUS2_norm, X_orig);
ssim_f2 = ssim(XFUS2_norm, X_orig);

fprintf('====================================================\n');
fprintf(' TABELA 1 - RESULTADOS METRICAS (CASO LEOPARDO)\n');
fprintf('====================================================\n');
fprintf('Imagem             | MSE       | PSNR (dB) | SSIM\n');
fprintf('----------------------------------------------------\n');
fprintf('leopard_fus1.tif   | %9.4f | %9.4f | %6.4f\n', mse_f1, psnr_f1, ssim_f1);
fprintf('leopard_fus2.tif   | %9.4f | %9.4f | %6.4f\n', mse_f2, psnr_f2, ssim_f2);
fprintf('====================================================\n\n');

%% =========================================================================
%% EXERCICIO 2: FUSAO SEM IMAGEM DE REFERENCIA (CONJUNTO BUTTERFLY)
%% =========================================================================
img_but1 = 'butterfly_1.tif';
img_but2 = 'butterfly_2.tif';

if exist(img_but1, 'file') && exist(img_but2, 'file')
    B1 = imread(img_but1);
    B2 = imread(img_but2);
else
    error('Arquivos do experimento Butterfly ausentes no diretorio.');
end

if size(B1, 3) > 1, B1 = rgb2gray(B1); end
if size(B2, 3) > 1, B2 = rgb2gray(B2); end

% Execucao da Fusao Wavelet Customizada
BFUS1_norm = manual_wavelet_fusion(B1, B2, 4, 'mean', 'max');
imwrite(BFUS1_norm, 'butterfly_fus1.tif');

BFUS2_norm = manual_wavelet_fusion(B1, B2, 4, 'min', 'max');
imwrite(BFUS2_norm, 'butterfly_fus2.tif');

% Calculo da Variancia Global conforme enunciado: mean(var(double(imagem)))
var_b1 = mean(var(double(BFUS1_norm)));
var_b2 = mean(var(double(BFUS2_norm)));

% Metodo Proposto: MSR (Metric of Structural Retention) via SSIM Cruzado
ssim_cross_b1 = (ssim(BFUS1_norm, B1) + ssim(BFUS1_norm, B2)) / 2;
ssim_cross_b2 = (ssim(BFUS2_norm, B1) + ssim(BFUS2_norm, B2)) / 2;

fprintf('====================================================\n');
fprintf(' TABELA 2 - RESULTADOS METRICAS (CASO BORBOLETA)\n');
fprintf('====================================================\n');
fprintf('Imagem              | Variancia Global | SSIM Cruzado MSR\n');
fprintf('----------------------------------------------------\n');
fprintf('butterfly_fus1.tif  | %16.4f | %15.4f\n', var_b1, ssim_cross_b1);
fprintf('butterfly_fus2.tif  | %16.4f | %15.4f\n', var_b2, ssim_cross_b2);
fprintf('====================================================\n');

%% PLOTAGEM EXPOSITIVA DOS RESULTADOS DAS FUSOES
figure('Name', 'Analise de Fusao Wavelet Manual', 'NumberTitle', 'off');
subplot(2,2,1); imshow(XFUS1_norm); title('Leopard Fus 1 (mean/max)');
subplot(2,2,2); imshow(XFUS2_norm); title('Leopard Fus 2 (min/max)');
subplot(2,2,3); imshow(BFUS1_norm); title('Butterfly Fus 1 (mean/max)');
subplot(2,2,4); imshow(BFUS2_norm); title('Butterfly Fus 2 (min/max)');

%% =========================================================================
%% FUNCOES LOCAIS (ALGORITMO DE FUSAO EM DOMINIO DE FREQUENCIA SUBST. WA_TOOLBOX)
%% =========================================================================

function out_img = manual_wavelet_fusion(I1, I2, levels, afusmeth, dfusmeth)
    % Executa a decomposicao piramidal e fusao estruturada de coeficientes
    img1 = double(I1);
    img2 = double(I2);
    
    % Redimensionamento para multiplos de 2^levels para viabilizar casamento de grades
    pad_r = mod(2^levels - mod(size(img1,1), 2^levels), 2^levels);
    pad_c = mod(2^levels - mod(size(img1,2), 2^levels), 2^levels);
    img1 = padarray(img1, [pad_r, pad_c], 'replicate', 'post');
    img2 = padarray(img2, [pad_r, pad_c], 'replicate', 'post');
    
    % Decomposicao via Transformada Wavelet Discreta Manual de N niveis
    [C1, S1] = manual_dwt2(img1, levels);
    [C2, ~] = manual_dwt2(img2, levels);
    
    Cfused = zeros(size(C1));
    
    % Isolamento do coeficiente de aproximacao (Frequencias Baixas)
    approx_length = S1(1,1) * S1(1,2);
    A1 = C1(1:approx_length);
    A2 = C2(1:approx_length);
    
    if strcmp(afusmeth, 'mean')
        Cfused(1:approx_length) = (A1 + A2) / 2;
    elseif strcmp(afusmeth, 'min')
        Cfused(1:approx_length) = min(A1, A2);
    else
        Cfused(1:approx_length) = max(A1, A2);
    end
    
    % Isolamento e fusao dos coeficientes de detalhes (Frequencias Altas)
    if strcmp(dfusmeth, 'max')
        Cfused(approx_length+1:end) = max(C1(approx_length+1:end), C2(approx_length+1:end));
    else
        Cfused(approx_length+1:end) = (C1(approx_length+1:end) + C2(approx_length+1:end)) / 2;
    end
    
    % Reconstrucao atraves da Transformada Inversa
    fused_double = manual_idwt2(Cfused, S1, levels);
    
    % Remocao do padding e normalizacao dinamica
    fused_double = fused_double(1:size(I1,1), 1:size(I1,2));
    out_img = uint8(mat2gray(fused_double) * 255);
end

function [C, S] = manual_dwt2(img, levels)
    S = zeros(levels + 2, 2);
    S(end, :) = size(img);
    current_img = img;
    details = cell(levels, 3);
    
    for L = levels:-1:1
        [H, W] = size(current_img);
        S(L+1, :) = [H, W];
        
        % Filtros Haar de decomposicao ortogonal espacial
        A = (current_img(1:2:end, 1:2:end) + current_img(2:2:end, 1:2:end) + current_img(1:2:end, 2:2:end) + current_img(2:2:end, 2:2:end)) / 4;
        H_det = (current_img(1:2:end, 1:2:end) - current_img(2:2:end, 1:2:end) + current_img(1:2:end, 2:2:end) - current_img(2:2:end, 2:2:end)) / 4;
        V_det = (current_img(1:2:end, 1:2:end) + current_img(2:2:end, 1:2:end) - current_img(1:2:end, 2:2:end) - current_img(2:2:end, 2:2:end)) / 4;
        D_det = (current_img(1:2:end, 1:2:end) - current_img(2:2:end, 1:2:end) - current_img(1:2:end, 2:2:end) + current_img(2:2:end, 2:2:end)) / 4;
        
        details{L, 1} = H_det;
        details{L, 2} = V_det;
        details{L, 3} = D_det;
        current_img = A;
    end
    S(1, :) = size(current_img);
    
    C = current_img(:)';
    for L = 1:levels
        C = [C, details{L,1}(:)', details{L,2}(:)', details{L,3}(:)']; %#ok<AGROW>
    end
end

function img = manual_idwt2(C, S, levels)
    approx_w = S(1,2); approx_h = S(1,1);
    approx_len = approx_h * approx_w;
    current_A = reshape(C(1:approx_len), [approx_h, approx_w]);
    idx = approx_len + 1;
    
    for L = 1:levels
        h_L = S(L+1, 1); w_L = S(L+1, 2);
        sub_w = h_L / 2; sub_h = w_L / 2;
        len = sub_w * sub_h;
        
        H_det = reshape(C(idx:idx+len-1), [sub_w, sub_h]); idx = idx + len;
        V_det = reshape(C(idx:idx+len-1), [sub_w, sub_h]); idx = idx + len;
        D_det = reshape(C(idx:idx+len-1), [sub_w, sub_h]); idx = idx + len;
        
        % Sintese inversa por expansao e combinacao de sub-bandas
        img_reconstructed = zeros(h_L, w_L);
        img_reconstructed(1:2:end, 1:2:end) = current_A + H_det + V_det + D_det;
        img_reconstructed(2:2:end, 1:2:end) = current_A - H_det + V_det - D_det;
        img_reconstructed(1:2:end, 2:2:end) = current_A + H_det - V_det - D_det;
        img_reconstructed(2:2:end, 2:2:end) = current_A - H_det - V_det + D_det;
        
        current_A = img_reconstructed;
    end
    img = current_A;
end