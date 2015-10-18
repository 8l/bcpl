
movb %al,20
movb %cl,20
movw %ax,20
movw %cx,20
	
movb %al,0(%ebx)
movb %cl,0(%ebx)
movw %ax,0(%ebx)
movw %cx,0(%ebx)
	
movb %al,20(%ebx)
movb %cl,20(%ebx)
movw %ax,20(%ebx)
movw %cx,20(%ebx)
	
movb %al,511(%ebx)
movb %cl,511(%ebx)
movw %ax,511(%ebx)
movw %cx,511(%ebx)

	
movb %al,0(%ebp)
movb %cl,0(%ebp)
movw %ax,0(%ebp)
movw %cx,0(%ebp)
	
movb %al,20(%ebp)
movb %cl,20(%ebp)
movw %ax,20(%ebp)
movw %cx,20(%ebp)
	
movb %al,511(%ebp)
movb %cl,511(%ebp)
movw %ax,511(%ebp)
movw %cx,511(%ebp)

	
movb $255,20
movw $1023,20
	
movb $255,0(%ebx)
movw $1023,0(%ebx)
	
movb $255,20(%ebx)
movw $1023,20(%ebx)
	
movb $255,511(%ebx)
movw $1023,511(%ebx)

	
movb $255,0(%ebp)
movw $1023,0(%ebp)
	
movb $255,20(%ebp)
movw $1023,20(%ebp)
	
movb $255,511(%ebp)
movw $1023,511(%ebp)

