from django.shortcuts import render


# Create your views here.
def index(request):
    context = {'title': '* B o n j o u r *',
               'content': 'Bonjour les amis!'}
    return render(request,
                  'bonjour/index.html', context)
