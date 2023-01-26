PHONIFY = 1
USAGE := {a.style('==>','bold')} {a.style('flakes ftw','header')} {a.style('<==','bold')}\n
-include .task.mk
$(if $(wildcard .task.mk),,.task.mk: ; curl -fsSL https://raw.githubusercontent.com/daylinmorgan/task.mk/v23.1.1/task.mk -o .task.mk)
