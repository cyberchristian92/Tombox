const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

async function main() {
  const profileDir = '/tmp/tombox-chrome-' + Date.now();
  fs.mkdirSync(profileDir, { recursive: true });

  console.log('Iniciando Chrome em modo headless com depuração...');
  const chromeProcess = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
    '--headless=new',
    '--user-data-dir=' + profileDir,
    '--remote-debugging-port=9222',
    '--window-size=360,800',
    '--disable-gpu',
    '--no-sandbox',
    'about:blank'
  ]);

  let targetPage = null;
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 500));
    try {
      const res = await fetch('http://127.0.0.1:9222/json/list');
      const list = await res.json();
      targetPage = list.find(t => t.type === 'page');
      if (targetPage) break;
    } catch (e) {}
  }

  if (!targetPage) {
    chromeProcess.kill();
    throw new Error('Não foi possível encontrar a página no Chrome');
  }

  console.log('Conectado à página:', targetPage.webSocketDebuggerUrl);
  const ws = new WebSocket(targetPage.webSocketDebuggerUrl);

  let id = 1;
  const callbacks = new Map();

  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.id && callbacks.has(data.id)) {
      callbacks.get(data.id)(data);
      callbacks.delete(data.id);
    }
  };

  await new Promise(r => ws.onopen = r);

  function send(method, params = {}) {
    return new Promise((resolve) => {
      const msgId = id++;
      callbacks.set(msgId, resolve);
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });
  }

  // Configura viewport 360x800 com scale factor 2
  await send('Emulation.setDeviceMetricsOverride', {
    width: 360,
    height: 800,
    deviceScaleFactor: 2,
    mobile: true,
  });

  await send('Page.enable');
  await send('Runtime.enable');

  async function capturar(url, nomeArquivo, esperaMs = 3500) {
    console.log(`Navegando para ${url} -> ${nomeArquivo}...`);
    await send('Page.navigate', { url });
    await new Promise(r => setTimeout(r, esperaMs));
    const res = await send('Page.captureScreenshot', { format: 'png' });
    const buffer = Buffer.from(res.result.data, 'base64');
    const dest = path.join(__dirname, '..', 'docs', 'screenshots', nomeArquivo);
    fs.writeFileSync(dest, buffer);
    console.log(`Salvo: ${dest} (${buffer.length} bytes)`);
  }

  // Garante tema claro inicialmente
  await send('Emulation.setAutoDarkModeOverride', { enabled: false });
  await send('Emulation.setEmulatedMedia', { media: 'screen', features: [{ name: 'prefers-color-scheme', value: 'light' }] });

  // Inicializa Flutter
  console.log('Inicializando Flutter e banco de dados...');
  await send('Page.navigate', { url: 'http://localhost:8085/#/' });
  await new Promise(r => setTimeout(r, 6000));

  // 1. Início (Claro)
  await capturar('http://localhost:8085/#/', '01-inicio.png', 4000);

  // 2. Locais (Claro)
  await capturar('http://localhost:8085/#/locais', '02-locais.png', 3500);

  // 3. Sala detalhe (Claro)
  await capturar('http://localhost:8085/#/locais/demo', '03-sala.png', 3500);

  // 4. Conferir (Claro)
  await capturar('http://localhost:8085/#/conferencia/demo', '04-conferir.png', 3500);

  // 5. Bens (Claro)
  await capturar('http://localhost:8085/#/bens', '05-bens.png', 3500);

  // 6. Ficha do bem (Claro)
  await capturar('http://localhost:8085/#/bens/010001', '06-ficha.png', 3500);

  // 7. Mais (Claro)
  await capturar('http://localhost:8085/#/mais', '07-mais.png', 3500);

  // --- ATIVA MODO ESCURO VIA EMULATION CDP ---
  console.log('Ativando Modo Escuro via CDP...');
  await send('Emulation.setAutoDarkModeOverride', { enabled: true });
  await send('Emulation.setEmulatedMedia', { media: 'screen', features: [{ name: 'prefers-color-scheme', value: 'dark' }] });

  // 8. Início (Dark)
  await capturar('http://localhost:8085/?dark=true#/', '01-inicio-dark.png', 4000);

  // 9. Ficha do bem (Dark)
  await capturar('http://localhost:8085/?dark=true#/bens/010001', '06-ficha-dark.png', 4000);

  // Remove test.png if present
  try {
    fs.unlinkSync(path.join(__dirname, '..', 'docs', 'screenshots', 'test.png'));
  } catch (_) {}

  ws.close();
  chromeProcess.kill();
  console.log('Todas as 9 capturas concluídas com sucesso!');
}

main().catch(err => {
  console.error('Erro na captura:', err);
  process.exit(1);
});
