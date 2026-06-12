# ☁️ Configuração do rclone + OneDrive para Backup
## Passo a passo para configurar o upload automático dos backups

---

### Pré-requisitos
- Acesso SSH ao **Pi5-108** (192.168.68.108)
- Sua conta Microsoft (Hotmail/Outlook) com OneDrive
- O `rclone` já está instalado (instalei hoje)

---

## Passo 1: Conectar no Pi5-108

Abra um terminal no seu computador e conecte via SSH:

```bash
ssh robert@192.168.68.108
```

## Passo 2: Iniciar a configuração do rclone

Dentro do SSH, rode:

```bash
rclone config
```

Você vai ver algo assim:

```
No remotes found, make a new one?
n) New remote
s) Set configuration password
q) Quit config
n/s/q>
```

## Passo 3: Criar o remote "onedrive"

Digite `n` e Enter:

```
name> onedrive
```

Depois ele pergunta o tipo. Digite `onedrive` e Enter:

```
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value:
...
Storage> onedrive
```

## Passo 4: Deixar client_id e client_secret vazios

Quando perguntar `client_id`, só dê Enter (vazio).
Quando perguntar `client_secret`, só dê Enter (vazio).

```
client_id> 
client_secret> 
```

## Passo 5: Escolher o tipo do OneDrive

Vai aparecer:

```
Choose a number from below, or type in your own value
 1 / OneDrive Personal or Business
   \ "onedrive"
 2 / Root Sharepoint site
   \ "sharepoint"
 3 / Sharepoint site name or URL
   \ "url"
 4 / Search for a Sharepoint site
   \ "search"
 5 / Type in your own Tenant ID
   \ "tenant"
```

Digite `1` e Enter (OneDrive pessoal).

## Passo 6: Configuração avançada (pular)

```
Edit advanced config?
y) Yes
n) No (default)
y/n> n
```

Digite `n` e Enter.

## Passo 7: Autenticar com a Microsoft

Agora o rclone vai tentar abrir seu navegador:

```
If your browser doesn't open automatically go to the following link:
http://127.0.0.1:53682/auth?state=xxxxx
Log in and authorize rclone for access
Waiting for code...
```

**Como não tem navegador no Pi, você precisa fazer o seguinte:**

1. No seu computador (qualquer um), abra o navegador
2. Acesse: **http://127.0.0.1:53682/auth?state=xxxxx** (o link exato que apareceu no terminal)
3. Faça login com sua conta Microsoft (robert_carvalho@hotmail.com)
4. Autorize o rclone
5. Volte ao terminal do Pi5-108 — ele vai mostrar "Success!"

> **Se não conseguir acessar 127.0.0.1 do seu computador**, use este comando em OUTRO terminal (no seu computador, não no SSH):
> ```bash
> ssh -L 53682:127.0.0.1:53682 robert@192.168.68.108
> ```
> Depois abra http://127.0.0.1:53682 no navegador do seu computador.

## Passo 8: Confirmar

Depois de autorizar, o terminal pergunta:

```
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> y
```

Digite `y` e Enter.

## Passo 9: Sair

```
Current remotes:

Name                 Type
====                 ====
onedrive             onedrive

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> q
```

Digite `q` e Enter para sair.

## Passo 10: Testar

Ainda no SSH do Pi5-108, teste se o OneDrive está funcionando:

```bash
rclone ls onedrive:/
```

Se aparecer uma lista de arquivos/pastas do seu OneDrive, está configurado! ✅

## Passo 11: Testar o backup completo

```bash
bash /home/robert/scripts/backup_rpi_v4.sh
```

Isso vai rodar o backup completo incluindo o upload para o OneDrive.

---

## Backup automático

O backup já está agendado no cron para rodar:
**Segunda, Quarta e Sexta às 03:30**

```bash
30 3 * * 1,3,5 /home/robert/scripts/backup_rpi_v4.sh >> /home/robert/scripts/backup_pipeline.log 2>&1
```

---

## Solução de problemas

| Problema | Solução |
|---|---|
| `rclone: command not found` | Rode `sudo apt install rclone -y` |
| "Failed to create file system" | O remote "onedrive" não foi criado — refaça os passos |
| "401 Unauthorized" | O token expirou — rode `rclone config` e reconfigure |
| Upload lento | Normal para primeiro upload (pode levar horas). Depois só envia diferenças |
| Quer mudar a pasta | Edite `ONEDRIVE_REMOTE="onedrive:/backups"` no script |
