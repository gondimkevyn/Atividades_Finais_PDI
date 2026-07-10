# PDI-Activities-2026

Repositório destinado ao armazenamento e documentação das atividades práticas desenvolvidas ao longo da disciplina de **Processamento Digital de Imagens (PDI)**.

**Autor:** Kevyn Gondim

---

## 📋 Resumo das Atividades Desenvolvidas

### 1. Equalização de Histograma

Nesta atividade, o objetivo foi trabalhar com o contraste de imagens digitais. Desenvolvemos funções para calcular a distribuição de tons de cinza de uma imagem e aplicamos uma técnica matemática clássica para espalhar essas intensidades. Isso permitiu melhorar significativamente a qualidade visual e revelar detalhes ocultos em imagens muito escuras ou com iluminação ruim.

### 2. Aumento Artificial de Dados (*Data Augmentation*)

Focada na preparação de dados para modelos de inteligência artificial aplicados à medicina. Criamos uma rotina para manipular e gerar novas versões de imagens de forma geométrica. Implementamos de forma manual operações de redimensionamento (ajustando a proporção), translação (deslocamento lateral), zoom centralizado e espelhamento horizontal. O objetivo foi expandir e balancear o banco de imagens para ajudar no treinamento de redes neurais.

### 3. Projeto de Morfologia Matemática Binária

Esta atividade consistiu na criação de um filtro baseado em formas geométricas para limpar e isolar objetos em imagens binárias (preto e branco). Implementamos do zero os operadores de erosão (que encolhe e elimina estruturas menores que um determinado tamanho) e dilatação (que expande e reconstrói as formas). Combinando essas técnicas, conseguimos eliminar com sucesso todos os quadrados pequenos de uma cena e restaurar perfeitamente apenas os objetos grandes.

### 4. Análise Quantitativa de Qualidade e Fusão de Imagens

Neste experimento, exploramos o conceito de fusão de imagens, que consiste em combinar duas fotos diferentes de uma mesma cena (cada uma com foco em uma região) para gerar uma única imagem final totalmente nítida. Para avaliar o resultado, aplicamos métricas estatísticas de erro e qualidade visual (como MSE, PSNR e SSIM), comparando diferentes critérios de combinação tanto em cenários onde tínhamos uma imagem perfeita de referência quanto em testes cegos.

### 5. Limiarização Global Iterativa

Trabalhamos com uma técnica automatizada de segmentação que busca separar o objeto principal do fundo da imagem definindo um ponto de corte ideal. O algoritmo calcula esse limite de forma repetitiva e inteligente com base na média dos pixels. O experimento serviu para analisar como o critério de parada influencia o resultado e para entender na prática por que métodos globais falham quando a imagem possui sombras ou iluminação que varia ao longo do cenário.

### 6. Filtragem no Domínio da Frequência e Alta Ênfase

Nesta prática, saímos do espaço comum da imagem e operamos diretamente no domínio da frequência usando a Transformada de Fourier. Analisamos o comportamento de filtros que suavizam texturas (passa-baixas) e filtros que destacam contornos (passa-altas). Além disso, criamos um filtro composto de Alta Ênfase que, aliado a um ajuste de contraste, foi capaz de realçar com extrema nitidez os detalhes e bordas de estruturas em imagens médicas de raio-X.

### 7. Roteiro de Conceitos: Filtragem Espacial (POGIL)

Uma atividade teórica e conceitual focada na compreensão das frequências espaciais em imagens. Analisamos como variações visuais (como bordas detalhadas, texturas finas e ruídos) correspondem a altas frequências, enquanto regiões homogêneas de fundo correspondem a baixas frequências. O roteiro cobriu os mecanismos de funcionamento de máscaras (*kernels*) de processamento linear e o desenho de filtros de média simples.

---

## 🛠️ Tecnologias Utilizadas

* **MATLAB** (Desenvolvimento de todos os algoritmos, pipelines e painéis gráficos de forma nativa e manual).
