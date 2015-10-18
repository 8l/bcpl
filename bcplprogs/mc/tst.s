 movl (%eax),%eax
 movl 12(%eax),%eax
 movl (%ecx),%eax
 movl 12(%ecx),%eax
 movl (%edx),%eax
 movl 12(%edx),%eax
 movl (%ebx),%eax
 movl 12(%ebx),%eax
 movl (%esp),%eax
 movl 12(%esp),%eax
 movl (%ebp),%eax
 movl 12(%ebp),%eax
 movl (%esi),%eax
 movl 12(%esi),%eax
 movl (%edi),%eax
 movl 12(%edi),%eax

 movl %eax,(%eax)
 movl %eax,12(%eax)
 movl %eax,(%ecx)
 movl %eax,12(%ecx)
 movl %eax,(%edx)
 movl %eax,12(%edx)
 movl %eax,(%ebx)
 movl %eax,12(%ebx)
 movl %eax,(%esp)
 movl %eax,12(%esp)
 movl %eax,(%ebp)
 movl %eax,12(%ebp)
 movl %eax,(%esi)
 movl %eax,12(%esi)
 movl %eax,(%edi)
 movl %eax,12(%edi)

 ret
 