/*
  Propósito:
    Criar uma representação visual do Sistema Solar usando arte ASCII, onde cada planeta é desenhado como uma esfera rotativa composta por caracteres, com texturas reativas ao áudio. 
    O utilizador pode navegar entre os planetas usando as setas esquerda/direita, e cada planeta tem características visuais distintas baseadas em suas propriedades astronómicas e reatividade ao som.
*/

int columns, lines;
int font_size = 16; // Fixado em 16 
PFont fon;

// Lista de caracteres  
char[] characters = {'.', ',', '*', 'x', '#', '1', '0', '░', '='};

// Sistema de navegação: 0=Sol, 1=Mercúrio, 2=Vénus, 3=Terra, 4=Marte, 5=Júpiter, 6=Saturno, 7=Úrano, 8=Neptuno
int currentPlanet = 3; // Começa na Terra (índice 3)
float planetRotation = 0;

void drawMiguel3(PGraphics pg, float amp, boolean beat) {
  // Inicialização única da fonte e dimensões da grelha
  if (fon == null) {
    fon = createFont("Courier", font_size);
    columns = pg.width / font_size;
    lines = pg.height / font_size;
  }

  // --- CONTROLO AUDIO-REATIVO PARA A VELOCIDADE ---
  float highFreqs = 0;
  if (fft != null) {
    float[] spec = new float[512];
    fft.analyze(spec);
    for (int i = 150; i < 350; i++) {
      highFreqs += spec[i];
    }
    highFreqs /= 200;
  }

  // Velocidade dinâmica baseada no áudio
  float baseSpeed = (currentPlanet >= 5) ? 0.008 : 0.015; 
  float rotationSpeed = baseSpeed + (highFreqs * 5.5) + (amp * 0.12);
  planetRotation += rotationSpeed;

  // --- DESENHO NA LAYER ---
  pg.beginDraw();
  pg.background(palette[3]); // #040813 (Espaço Profundo)

  pg.textFont(fon);
  pg.textSize(font_size); 
  pg.textAlign(CENTER, CENTER);

  // Definição da cor cinza estável pedida (#AFAFAF)
  color grayPlanet = pg.color(175, 175, 175);

  // Dimensões base e posicionamento centralizado
  float radius = pg.height * 0.32; // Reduzido ligeiramente para dar espaço ao título em ASCII
  float centerX = pg.width / 2.0;
  float centerY = pg.height / 2.0 + (font_size * 1.5); // Deslocado para baixo para centrar com o texto decorativo

  // Definição de propriedades astronómicas para cada corpo do Sistema Solar
  float axialTilt = 0.0;
  /* String planetName = ""; */
  
  switch(currentPlanet) {
    case 0: axialTilt = 0.12; /* planetName = "SUN"; */ break;
    case 1: axialTilt = 0.01; /* planetName = "MERCURY"; */ break;
    case 2: axialTilt = 0.05; /* planetName = "VENUS";  */break;
    case 3: axialTilt = 0.41; /* planetName = "EARTH";  */break;
    case 4: axialTilt = 0.44; /* planetName = "MARS"; */ break;
    case 5: axialTilt = 0.05; /* planetName = "JUPYTER"; */ break;
    case 6: axialTilt = 0.47; /* planetName = "SATURN"; */ break;
    case 7: axialTilt = 1.71; /* planetName = "URANUS"; */ break;
    case 8: axialTilt = 0.50; /* planetName = "NEPTUNE"; */ break;
  }

  // Percorrer a grelha ASCII
  for (int y = 0; y < lines; y++) {
    for (int x = 0; x < columns; x++) {
      
      float posX = x * font_size + (font_size / 2.0);
      float posY = y * font_size + (font_size / 2.0);

      // --- RENDER DO NOME DO PLANETA EM ASCII (No topo do ecrã) ---
      /* if (y == 2) {
        int textLength = planetName.length();
        int startX = (columns - textLength) / 2;
        if (x >= startX && x < startX + textLength) {
          char letter = planetName.charAt(x - startX);
          pg.fill(grayPlanet);
          pg.text(letter, posX, posY);
          continue; // Avança para a próxima célula da grelha
        }
      } */
      
      // Linha decorativa por baixo do nome
      /* if (y == 3 && x > (columns - planetName.length())/2 - 2 && x < (columns + planetName.length())/2 + 1) {
        pg.fill(pg.color(100, 100, 100));
        pg.text('-', posX, posY);
        continue;
      } */

      float dx = posX - centerX;
      float dy = posY - centerY;
      boolean planetBodyDrawn = false;

      // 1. DESENHAR O CORPO DO PLANETA 3D
      if (dx * dx + dy * dy <= radius * radius) {
        planetBodyDrawn = true;
        float dz = sqrt(radius * radius - (dx * dx + dy * dy));

        // Rotação tridimensional com a inclinação axial do planeta atual
        float rY = dy * cos(axialTilt) - dz * sin(axialTilt);
        float rZ = dy * sin(axialTilt) + dz * cos(axialTilt);
        float rX = dx;

        // Mapeamento esférico para evitar distorções polares
        float longitude = atan2(rZ, rX) + planetRotation;
        float latitude = acos(rY / radius);

        float nX = sin(latitude) * cos(longitude);
        float nY = cos(latitude);
        float nZ = sin(latitude) * sin(longitude);

        char charToDraw = ' ';
        color bodyColor = grayPlanet; // Padrão limpo e cinza para os planetas problemáticos
        boolean isSun = (currentPlanet == 0);

        // --- MOTOR DE TEXTURAS REATIVAS DO SISTEMA SOLAR ---
        switch(currentPlanet) {
          
          case 0: // ==================== O SOL ====================
            float sunNoise = noise(nX * 3.5, nY * 3.5, nZ * 3.5 + planetRotation * 0.5);
            if (beat) sunNoise += amp * 0.3;
            int sunIdx = int(map(sunNoise, 0.2, 0.8, 4, 8));
            charToDraw = characters[constrain(sunIdx, 4, 8)];
            bodyColor = (sunNoise > 0.5) ? palette[6] : palette[5]; // Mantém o aspeto de energia incandescente
            break;

          case 1: // ==================== MERCÚRIO ====================
            float mercNoise = noise(nX * 5.0, nY * 5.0, nZ * 5.0);
            int mercIdx = int(map(mercNoise, 0.3, 0.7, 0, 4));
            charToDraw = characters[constrain(mercIdx, 0, 4)];
            bodyColor = grayPlanet; // Corrigido para Cinza Estável
            break;

          case 2: // ==================== VÉNUS ====================
            float venusNoise = noise(nX * 2.0, nY * 1.5, nZ * 2.0);
            int venusIdx = (venusNoise > 0.5) ? 7 : 4;
            charToDraw = characters[venusIdx];
            bodyColor = grayPlanet; // Corrigido para Cinza Estável (remove o verde/vermelho tóxico)
            break;

          case 3: // ==================== TERRA ====================
            float noiseLand = noise(nX * 2.2 + 50, nY * 2.2 + 50, nZ * 2.2);
            if (beat) noiseLand += (amp * 0.05); 
            if (noiseLand > 0.47) {
              charToDraw = characters[(noiseLand > 0.6) ? 4 : 7];
              bodyColor = palette[7]; // Mantém o Verde Natural
            } else {
              charToDraw = characters[(noiseLand > 0.38) ? 1 : 0];
              bodyColor = palette[5]; // Mantém o Azul Ciano
            }
            break;

          case 4: // ==================== MARTE ====================
            float marsNoise = noise(nX * 3.5, nY * 3.5, nZ * 3.5);
            int marsIdx = int(map(marsNoise, 0.2, 0.8, 1, 5)); 
            charToDraw = characters[constrain(marsIdx, 1, 5)];
            bodyColor = palette[6]; // Mantém o Planeta Vermelho icónico
            break;

          case 5: // ==================== JÚPITER ====================
            float jupBands = sin(nY * 14.0 + noise(nX * 2.5, nZ * 2.5) * 3.0);
            float jupNoise = map(jupBands, -1.0, 1.0, 0.0, 1.0);
            if (abs(nY - 0.2) < 0.15 && abs(nX - 0.1) < 0.2) {
              charToDraw = '0';
              bodyColor = palette[6]; // Grande mancha vermelha
            } else {
              charToDraw = characters[int(map(jupNoise, 0, 1, 3, 7))];
              bodyColor = (jupNoise > 0.5) ? grayPlanet : palette[1]; // Mistura o cinza limpo com faixas escuras
            }
            break;

          case 6: // ==================== SATURNO ====================
            float satBands = sin(nY * 20.0 + noise(nX * 1.5, nZ * 1.5) * 1.5);
            float satNoise = map(satBands, -1.0, 1.0, 0.0, 1.0);
            charToDraw = characters[int(map(satNoise, 0, 1, 0, 4))];
            bodyColor = grayPlanet; // Corrigido para Cinza Estável
            break;

          case 7: // ==================== ÚRANO ====================
            float uranusNoise = noise(nX * 1.5, nY * 1.5, nZ * 1.5);
            charToDraw = characters[(uranusNoise > 0.5) ? 7 : 0];
            bodyColor = palette[5]; // Mantém o Ciano Metano para contrastar com os anéis
            break;

          case 8: // ==================== NEPTUNO ====================
            float nepNoise = noise(nX * 4.0, nY * 4.0 + planetRotation * 0.2, nZ * 4.0);
            charToDraw = characters[(nepNoise > 0.55) ? 4 : 3];
            bodyColor = grayPlanet; // Corrigido para Cinza Estável
            break;
        }

        // 5. Efeito de Iluminação 3D / Sombreado Esférico (Shading)
        float shading = isSun ? 1.0 : map(dz, 0, radius, 0.25, 1.0);
        
        pg.fill(pg.color(red(bodyColor) * shading, green(bodyColor) * shading, blue(bodyColor) * shading));
        pg.text(charToDraw, posX, posY);
      }

      // 2. SISTEMA DE ANÉIS 
      if (!planetBodyDrawn && (currentPlanet == 6 || currentPlanet == 7)) {
        
        float cosTilt = cos(-axialTilt);
        float sinTilt = sin(-axialTilt);
        
        float ringX = dx * cosTilt - dy * sinTilt;
        float ringY = dx * sinTilt + dy * cosTilt;
        
        float flatness = (currentPlanet == 7) ? 0.18 : 0.28;
        float ringDist = sqrt(ringX * ringX + (ringY / flatness) * (ringY / flatness));

        float innerR = radius * 1.25;
        float outerR = radius * 2.25;

        if (ringDist >= innerR && ringDist <= outerR) {
          boolean isBehind = (ringY * (currentPlanet == 7 ? -1 : 1) < 0);
          
          if (!isBehind) {
            float ringNoise = noise(ringDist * 0.15, planetRotation * 0.05);
            if (beat) ringNoise += amp * 0.08;
            
            char ringChar = characters[int(map(ringNoise, 0.2, 0.8, 0, 3))];
            color ringColor = (currentPlanet == 6) ? grayPlanet : palette[5]; // Anéis acompanham a nova palete cinza em Saturno
            
            float ringFade = map(ringDist, innerR, outerR, 1.0, 0.35);
            
            pg.fill(pg.color(red(ringColor) * ringFade, green(ringColor) * ringFade, blue(ringColor) * ringFade));
            pg.text(ringChar, posX, posY);
          }
        }
      }
      
    }
  }

  pg.endDraw();
}

// Controlos de Interação por Teclado nativos para esta Layer
void miguelLayer3KeyPressed() {
  if (key == CODED) {
    if (keyCode == RIGHT) {
      currentPlanet = (currentPlanet + 1) % 9; // Navega em ciclo pelos 9 astros para a direita
    } else if (keyCode == LEFT) {
      currentPlanet = currentPlanet - 1;
      if (currentPlanet < 0) currentPlanet = 8; // Retrocede em ciclo para a esquerda
    }
  }
}