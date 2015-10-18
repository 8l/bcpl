/*

This program attempts to solve a computationally difficult jigsaw
puzzle with n**2 pieces that are almost square but have edges that
have possible shapes A, B, C, D, 1, 2, 3 and 4. The only edges that
interlock are A-1, B-2, C-3 and D-4. Each piece can be rotated or
turned over. The aim is to fit the pieces together to form an n x n
square.

Example puzzles

2x2
Pieces:    DA23  AB41  BC12  DC43

Solution:   - D -   - A -
           |     | |     |
           3     A 1     B
           |     | |     |
            - 2 -   - 4 -
            - B -   - D -
           |     | |     |
           2     C 3     C
           |     | |     |
            - 1 -   - 4 -


3x3

4x4

5x5


*/
