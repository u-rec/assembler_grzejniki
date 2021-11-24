#include<stdlib.h>
#include <stdio.h>

extern void start (int szer, int wys, float *M, float C, float waga);

extern void place (int ile, int x[], int y[], float temp[]);

extern void step(int i);

#define SIZEOFFLOAT 4
#define SIZEOFINT 4

void print_state(float *tab, int szer, int wys, int ktora) {
        ktora *= szer * wys;
        for(int i = 0; i < wys; i++) {
                for (int j = 0; j< szer; j++) 
                        printf("%8.2f", tab[i*szer + j + ktora]);
                printf("\n");
        }
        getchar();
        printf("\n\n");
}

int main(int argc, char** argv) {
        if (argc < 4)
                return 1;
        FILE *file = fopen(argv[1], "r");
        int steps;
        float flux;
        sscanf(argv[2], "%d", &steps);
        sscanf(argv[3], "%f", &flux);
        if (file <= 0) {
                dprintf(2, "Nie ma pliku %s!\n", argv[1]);
                return 1;
        }
        int width, height;
        float C;
        fscanf(file, "%d %d %f", &width, &height, &C);
        float *matrix = malloc(2 * width * height * SIZEOFFLOAT);
        for (int i = 0; i < width* height; i++) {
                fscanf(file, "%f", &matrix[i]);
        }
        int g_num;
        fscanf(file, "%d", &g_num);
        int *x, *y;
        float *temp;
        x = malloc(g_num * SIZEOFINT);
        y = malloc(g_num * SIZEOFINT);
        temp = malloc(g_num * SIZEOFFLOAT);
        for(int i = 0; i < g_num; i++) {
                fscanf(file, "%d %d %f", &x[i], &y[i], &temp[i]);
        }
        fclose(file);
        start (width, height, matrix, C, flux);
        place(g_num, x, y, temp);
        print_state(matrix,width, height, 0);
        for (int i = 0; i < steps; i++)
                step(i);
        return 0;

}
