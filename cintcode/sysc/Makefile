sdl:
	gcc -o sdltst sdltst.c `sdl-config --cflags --libs`

sdldrawtest:
	gcc -o sdldrawtest sdldrawtest.c `sdl-config --cflags --libs` ../obj/sdldrawlib.o
#	gcc -o sdldrawtest sdldrawtest.c `sdl-config --cflags --libs` /usr/local/lib/libSDL_draw.a

clean:
	rm -f sdltst sdldrawtest
