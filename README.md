<div align="center">

# 📬 Asistente de Correos TUP

**Atiende el correo institucional de la Tecnicatura Universitaria en Programación (TUP, UTN) desde Claude Code: lee las consultas, las clasifica y deja las respuestas listas para revisar y enviar.**

![version](https://img.shields.io/badge/versión-0.3.0-1f5fa8)
![licencia](https://img.shields.io/badge/licencia-Apache--2.0-1a7f45)
![plataforma](https://img.shields.io/badge/Claude%20Code-terminal%20y%20escritorio-6b7684)

</div>

---

> La IA lee, clasifica y redacta. **Lo que dice la respuesta lo decide una base de conocimiento validada por la persona**, separada por facultad y modalidad. **Lo que sale del buzón lo decide la persona, correo por correo.**

Pensada para gente **sin conocimiento técnico**: habla en castellano simple, explica antes de hacer y va de a un paso. No instala servidores ni pide contraseñas.

---

## ✨ Qué hace

- 📥 **Lee la bandeja** y lista lo que está sin responder.
- 🗂️ **Clasifica** cada consulta por tema, **facultad** y **modalidad** — razonando, no por palabras fijas.
- ✍️ **Redacta borradores** desde una base de respuestas validada, **adaptando el tono** (formal o informal según el correo).
- ✅ **Envía solo con tu OK**, uno por uno, con adjuntos si hacen falta.
- 📊 **Hace informes** del estado del correo (rápido en el chat o en PDF).
- 🔒 **Nunca inventa datos** y **nunca mezcla facultades**.

## 🔌 Cómo se conecta al correo

Dos caminos, según el buzón:

| Camino | Cómo conecta | Cuándo se usa |
|---|---|---|
| **Gmail** | Conector oficial de Claude (un login de Google) | El buzón es Gmail |
| **Microsoft 365 (Outlook clásico)** | A través del Outlook de escritorio ya instalado, por su interfaz COM | El buzón es Microsoft y el conector oficial está bloqueado por el administrador |
| Microsoft 365 (conector) | Conector oficial de Claude | Si el administrador de la facultad lo aprueba |

El **modo Outlook clásico** no usa token, no abre el navegador y no necesita el consentimiento del administrador: la skill le da órdenes al Outlook que ya está abierto y con tu sesión iniciada, como lo haría una macro. Quien habla con Microsoft es Outlook (la app oficial), con tu login y tu MFA.

```
Microsoft 365  ⇄  Outlook en tu PC  ⇄  la skill
              login+MFA          COM (órdenes)
             (app oficial)      "listá / redactá / enviá"
```

## 🧠 La base de conocimiento

Es lo único de lo que la skill saca la información institucional, y **la valida la persona**. Vive en archivos Markdown locales, **uno por tema**, en `~/.correos-tup/conocimiento/` (editables a mano):

```
inscripcion-y-admision · cursada · examenes · tramites-administrativos
acceso-al-campus · becas-y-aranceles · contactos-y-derivaciones
```

Cada entrada lleva su **Ámbito** (facultad), **Modalidad** y **Tono sugerido**. **Nunca** guarda datos personales ni contraseñas. Crece solo con preguntas nuevas distintas (se estanca, queda navegable), y lo que no está validado sale con un hueco `[COMPLETAR]` en vez de un dato inventado.

## 🚀 Instalación

Es una skill de Claude Code: va en tu carpeta de skills.

```bash
git clone https://github.com/cachi001/Skill-Asistente-de-Correos.git \
  ~/.claude/skills/tup-asistente-correos
```

La primera vez, Claude te guía para conectar el buzón (Gmail con un clic, o agregar la cuenta al Outlook clásico).

## 💬 Uso

Le hablás en castellano, por ejemplo:

> «Ponete al día con los correos de la tecnicatura»
> «¿Qué consultas tengo sin responder en el mail?»
> «Armemos las respuestas tipo con lo que ya contesté»

La skill muestra un menú corto, arma la tabla de clasificación y te propone cada respuesta con su fuente. **Nada sale sin tu OK.**

## 📁 Estructura

```
tup-asistente-correos/
├── SKILL.md                      # instrucciones de la skill
├── README.md
├── VERSION
├── references/
│   ├── conectar-buzon.md         # conectar Gmail / Microsoft 365
│   ├── outlook-clasico.md        # modo Outlook clásico (COM): requisitos y uso
│   ├── base-de-conocimiento.md   # armado, Ámbito, modalidad, mantenimiento
│   └── redaccion.md              # forma y tono (incluye tono adaptativo)
├── assets/
│   ├── plantilla-entrada.md      # formato de cada entrada de la base
│   └── outlook-clasico/          # scripts COM (ocultos)
│       ├── leer-bandeja.ps1
│       ├── leer-correo.ps1
│       ├── crear-borrador.ps1
│       └── enviar-borrador.ps1
└── docs/                         # informes del proyecto (PDF)
```

## 🧭 Decisiones de diseño

- **Solo instrucciones, sin servidor propio.** Usa los conectores oficiales y, para Microsoft sin admin, el Outlook ya instalado. Menos cosas que instalar y que puedan romperse.
- **Base en Markdown local, no en una base de datos.** Es criterio humano: la persona la lee, valida y corrige en segundos.
- **Ámbito por entrada.** Un trámite cambia entre facultades; marcar la facultad evita darle a un alumno el procedimiento de otra sede.
- **Borrador primero, envío después.** Crear un borrador no tiene consecuencias; enviar sí. Un OK vale por un solo correo.

## 📄 Licencia

[Apache-2.0](LICENSE)
