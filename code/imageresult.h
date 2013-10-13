#ifndef __IMAGERESULT__
#define __IMAGERESULT__
#include <cstdio>
#include "forests.h"
#include "gridcode.h"
#include "mylib.h"
template <class type>
void rgb2gray(Grid<type> &gray, Array3<type> &rgb, float offset = 0, float scale = 1) {
    int H = rgb.height, W = rgb.width;
    float co[3] = { 0.299, 0.587, 0.114 };
    gray.reset(H, W);
    float grayscale;
    for (int i = 0; i < H; ++i)
        for (int j = 0; j < W; ++j) {
            grayscale = 0.5;
            for (int k = 0; k < 3; ++k)
                grayscale+=rgb[k][i][j]*co[k];
            if (offset == 0)
                gray[i][j] = grayscale;
            else gray[i][j] = scale*grayscale+offset-256*scale;
        }
}

template<class type>
/*img is the output image*/
void draw_tree(Grid<type> &img, Edge *trees, int n, int times, int color = -1){
    int H = img.height/(1+times), W = img.width/(1+times);
    Edge e; int temp, edge_color;
    for (int k = 1; k <= n; ++k) {
        e = trees[k];
        if (e.a > e.b) {
            temp = e.a; e.a = e.b; e.b = temp;
        }

        int i = (e.a-1)/W, j = (e.a-1)%W;
        int I = i*(times+1), J = j*(times+1);
        edge_color = color<0? img[I][J]:color;
        if (e.b == e.a+1)
            for (int ii = 0; ii < times; ++ii)
                img[I+ii][J+times] = edge_color;
            //img[I+times/2][J+times] = 0;   //addLeftEdge
        else
            for (int jj = 0; jj < times; ++jj)
                img[I+times][J+jj] = edge_color;
            //img[I+times][J+times/2] = 0;//addBottomEdge(e.a,e.b);
    }
}

template<class type>
void draw_image(Grid<type> &img, Grid<type> origin, int times) {
    int H = origin.height, W = origin.width;
    img.reset(H*(1+times), W*(1+times));
    //printf("H = %d, W = %d\n", H, W);
    for (int i = 0; i < H*(1+times); ++i)
        for (int j = 0; j < W*(1+times); ++j)
            img[i][j] = 127.5;

    for (int i = 0; i < H; ++i)
        for (int j = 0; j < W; ++j) {
            int I = i*(times+1), J = j*(times+1);   //I and J are index in the img; ERRORR: j*(1+times) instead of j*times
            for (int ii=0; ii < times; ++ii)
                for (int jj = 0; jj < times; ++jj)
                    img[I+ii][J+jj] = origin[i][j];
        }
}

template<class type>
void draw_tree_and_image(Grid<type> &img, Grid<type> &origin, Edge *trees, int n, int times, int color = -1) {
    draw_image(img, origin, times);
    draw_tree(img, trees, n, times, color);
}

template<class type>
void draw_tree_and_RGBimage(Grid<type> &img, Array3<type> &rgb, Edge *trees, int n, int times, int color = -1) {
    Grid<type> gray;
    rgb2gray(gray, rgb);
    draw_tree_and_image(img, gray, trees, n, times, color);
}

template <class type>
void draw_tree_difference(Grid<type> &img, Grid<type> &origin, Edge *tree1, int n1, Edge *tree2, int n2, int times) {
    Edge *only1 = (Edge *) malloc((n1+2) * sizeof(Edge));   // edges in tree1 only
    Edge *only2 = (Edge *) malloc((n2+2) * sizeof(Edge));   // edges in tree2 only
    Edge *inter = (Edge *) malloc(mylib::min(n1+2, n2+2) * sizeof(Edge));  // edges in the intersection of tree1 and tree2
    //calc_tree_difference
    int cnt1 = 0, cnt2 = 0, cnti = 0;
    int i = 1, j = 1;
    while (true) {
        while(i <= n1 && j <= n2 && tree1[i]>tree2[j]) only2[++cnt2] = tree2[j++];
        if (j > n2) break;
        else if (tree1[i] == tree2[j]){
            inter[++cnti] = tree1[i++];
            ++j;
        }
        while (i <= n1 && j <= n2 && tree2[j]>tree1[i]) only1[++cnt1] = tree1[i++];
        if (i > n1) break;
        else if (tree1[i] == tree2[j]) {
            inter[++cnti] = tree1[i++];
            ++j;
        }
    }
    while (i <= n1) only1[++cnt1] = tree1[i++];
    while (j <= n2) only2[++
        cnt2] = tree2[j++];

    draw_image(img, origin, times);
    draw_tree(img, inter, cnti, times);
    draw_tree(img, only1, cnt1, times, 255);
    draw_tree(img, only2, cnt2, times, 0);
}

template <class type>
void draw(type img, bool rgb) {
    printf("%d\n", rgb);
}

template <class type>
void draw_tree_differenceRGB(Grid<type> &img, Array3<type> &rgb, Edge *tree1, int n1, Edge *tree2, int n2, int times) {
    Grid<type> gray;
    rgb2gray(gray, rgb, 127.5, 0.35);
    draw_tree_difference(img, gray, tree1, n1, tree2, n2, times);
}

template<class type>
void compute_support(Grid<type> &support, Forest &forest, int x, int y, int W, double sigma) {
    forest.order_of_visit(x, y, W);
    forest.compute_support(support, sigma);
}

template <class type>
void draw_support_map(Grid<type> &output_support, Forest &support_forest, Graph &g, int x, int y, int times, double sigma = 0.1*255) {
    Grid<type> small_support;
    small_support.reset(g.H, g.W);
    compute_support(small_support, support_forest, x, y, g.W, sigma);
    draw_tree_and_image(output_support, small_support, g.trees, g.n, times);
}
#endif // ___IMAGERESULT__