<div align="center">

# 📬 Asistente de Correos TUP

**Ayuda a responder los correos de un buzón institucional o de Gmail de la Tecnicatura Universitaria en Programación (TUP, UTN) desde Claude Code, sea cual sea su uso: lee lo que llegó, lo clasifica, aprende de cómo ya se respondió y deja las respuestas listas para revisar y enviar. También atiende buzones compartidos.**

![version](https://img.shields.io/badge/versión-0.5.0-1f5fa8)
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
- ✅ **Envía solo con tu OK**, uno por uno, con adjuntos si hacen falta. Cada borrador tiene un **código de envío de un solo uso**: sin él no sale, y no se puede mandar dos veces.
- 🔒 **Modo solo lectura** por buzón: si un correo es solo para mirar, la skill no puede armar ni enviar nada desde ahí, aunque alguien lo pida por error.
- 📚 **Aprende de cómo ya se respondió**: recorre los enviados una vez y después encuentra al instante cómo se contestó algo parecido.
- ⏳ **Te muestra qué está haciendo**: pasos numerados en el chat y una ventanita con barra y tiempo restante para lo que tarda.
- 📊 **Hace informes** del estado del correo (rápido en el chat o en PDF).
- 🔒 **Nunca inventa datos** y **nunca mezcla facultades**.

## 🔌 Cómo se conecta al correo

Dos caminos, según el buzón:

| Camino | Cómo conecta | Cuándo se usa |
|---|---|---|
| **Gmail** | Conector oficial de Claude (un login de Google) | El buzón es Gmail |
| **Microsoft 365 (Outlook clásico)** | A través del Outlook de escritorio ya instalado, por su interfaz COM | El buzón es Microsoft 365, incluidos los buzones compartidos |

El **modo Outlook clásico** no usa token, no abre el navegador y no necesita ningún permiso del administrador: la skill le da órdenes al Outlook que ya está abierto y con tu sesión iniciada, como lo haría una macro. Quien habla con Microsoft es Outlook (la app oficial), con tu login y tu MFA.

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

## Antes de empezar

Necesitás:

- **Claude Code** instalado (terminal o app de escritorio), con tu sesión iniciada.
- **Node.js**, para el comando de instalación (`npx`).
- Según tu correo:
  - **Gmail**: el conector de Gmail activado. En Claude Code se activa en claude.ai, en
    Configuración, Conectores, con la misma cuenta con la que usás Claude Code.
  - **Microsoft 365**: una PC con Windows y el **Outlook clásico** de escritorio instalado.
    Si tu cuenta todavía no está en Outlook, la skill te abre la ventana para agregarla.
- **El conector de Google Sheets** (opcional), para llevar la planilla de seguimiento de
  correos. Sin él, la planilla queda guardada en tu computadora.

## Instalación

**La forma más fácil: pedíselo a Claude.** Abrí Claude Code y pegale esta frase:

> Instalá la skill de correos con `npx skills add https://github.com/cachi001/Skill-Asistente-de-Correos -g -a claude-code -y`. Si me falta Node.js, instalalo vos primero. Después revisá con `revisar-equipo` si mi Outlook está listo.

Claude hace todo y te va contando qué hace. Si te pide permiso para correr algo, aceptá.

**Si preferís hacerlo vos**, en una terminal:

```bash
npx skills add https://github.com/cachi001/Skill-Asistente-de-Correos -g -a claude-code -y
```

Reiniciá Claude Code y listo. Para comprobar que quedó instalada, escribí `/` y buscá
**tup-asistente-correos**, o pedile directamente «ponete al día con los correos».

Para **actualizarla** más adelante:

```bash
npx skills update tup-asistente-correos -g -y
```

La primera vez que la uses, la skill revisa qué correos tenés conectados, te pregunta para
qué usás el buzón y crea sola la carpeta de la base de respuestas en
`~/.correos-tup/conocimiento/`. No te pide contraseñas: si hay que iniciar sesión, la
escribís vos en la ventana de Google o de Microsoft.

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
│   ├── conectar-buzon.md         # conectar Gmail
│   ├── outlook-clasico.md        # modo Outlook clásico (COM): requisitos y uso
│   ├── base-de-conocimiento.md   # armado, Ámbito, modalidad, mantenimiento
│   └── redaccion.md              # forma y tono (incluye tono adaptativo)
├── assets/
│   ├── plantilla-entrada.md      # formato de cada entrada de la base
│   └── outlook-clasico/          # scripts COM (ocultos)
│       ├── revisar-equipo.ps1      # chequeo al empezar
│       ├── agregar-cuenta.ps1      # abre la ventana para sumar una cuenta
│       ├── esperar-buzon.ps1       # barra mientras baja una cuenta nueva
│       ├── listar-buzones.ps1
│       ├── modo-buzon.ps1          # solo lectura por buzón
│       ├── ponerse-al-dia.ps1      # todo lo sin responder, en una pasada
│       ├── indexar-enviados.ps1    # aprende de los enviados (una vez)
│       ├── buscar-respuestas.ps1   # cómo se respondió antes, al instante
│       ├── buzon-comun.ps1
│       ├── leer-bandeja.ps1
│       ├── leer-correo.ps1
│       ├── crear-borrador.ps1
│       └── enviar-borrador.ps1
└── docs/                         # informes del proyecto (PDF)
```

## 🧭 Decisiones de diseño

- **Solo instrucciones, sin servidor propio.** Usa el conector oficial de Gmail y, para Microsoft, el Outlook ya instalado. Menos cosas que instalar y que puedan romperse.
- **Base en Markdown local, no en una base de datos.** Es criterio humano: la persona la lee, valida y corrige en segundos.
- **Ámbito por entrada.** Un trámite cambia entre facultades; marcar la facultad evita darle a un alumno el procedimiento de otra sede.
- **Borrador primero, envío después.** Crear un borrador no tiene consecuencias; enviar sí. Un OK vale por un solo correo.

## 📄 Licencia

[Apache-2.0](LICENSE)
