/* int columns, lines;
int font_size = 16;
PFont fonte;

char[] characters = {'.', ',', '*', 'x', '#', '1', '0', '░', '='};

void drawPetunia1(PGraphics pg, float amp, boolean beat){
    if (fonte == null) {
        fonte = createFont("Courier", font_size);
        columns = pg.width / font_size;
        lines = pg.height / font_size;
    }

    pg.beginDraw();
    pg.clear();

    pg.textFont(fonte);
    pg.textSize(font_size); 
    pg.textAlign(CENTER, CENTER);

    for (int y = 0; y < lines; y++) {
        for (int x = 0; x < columns; x++) {
            float posX = x * font_size + (font_size / 2);
            float posY = y * font_size + (font_size / 2);

            pg.fill(palette[8]); 
            pg.text(characters[int(random(characters.length))], posX, posY);
        }
    }

    pg.endDraw();
} */