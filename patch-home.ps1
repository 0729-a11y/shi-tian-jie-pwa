$fp = 'C:\Users\lenovo\AppData\Roaming\TRAE SOLO CN\ModularData\ai-agent\work-mode-projects\6a6847f12789806c2836b315\shi-tian-jie\pages\home.html'
$tpl = 'C:\Users\lenovo\AppData\Roaming\TRAE SOLO CN\ModularData\ai-agent\work-mode-projects\6a6847f12789806c2836b315\shi-tian-jie\mood-panel-template.txt'

$c = [System.IO.File]::ReadAllText($fp, [System.Text.Encoding]::UTF8)
$moodPanel = [System.IO.File]::ReadAllText($tpl, [System.Text.Encoding]::UTF8)

# 1. 修复 quote emoji 乱码
$c = $c.Replace('<span style="font-size:18px">��</span>', '<span style="font-size:18px">✨</span>')

# 2. 清空 stat 数值
$c = $c.Replace('<div class="stat-value">¥86</div>', '<div class="stat-value">-</div>')
$c = $c.Replace('<div class="stat-value">1200<span class="stat-unit">ml</span></div>', '<div class="stat-value">-<span class="stat-unit">ml</span></div>')
$c = $c.Replace('<div class="stat-value">��</div>', '<div class="stat-value">?</div>')
$c = $c.Replace('<div class="stat-value">0<span class="stat-unit">min</span></div>', '<div class="stat-value">-<span class="stat-unit">min</span></div>')

# 3. 心情 stat-card 改为锚点到 #mood，并给数值加 id
$c = $c.Replace('<a href="home.html" class="stat-card" style="--stat-color:var(--yellow-500);--stat-soft:var(--yellow-100)">', '<a href="#mood" class="stat-card" style="--stat-color:var(--yellow-500);--stat-soft:var(--yellow-100)">')
$c = $c.Replace('<div class="stat-value">?</div>', '<div class="stat-value" id="mood-stat">?</div>')

# 4. 在 stats-row 结束后、待办打卡 card 前插入心情面板
$marker = @'
    </div>
    <div class="card">
      <div class="card-title"><span class="icon-dot" style="--module-color:var(--green-500)"></span>待办打卡</div>
'@
$replacement = "    </div>`n" + $moodPanel + "`n    <div class=\"card\">`n      <div class=\"card-title\"><span class=\"icon-dot\" style=\"--module-color:var(--green-500)\"></span>待办打卡</div>`n"
$c = $c.Replace($marker, $replacement)

# 5. 清空待办打卡
$oldTodo = @'
      <div class="todo-grid">
        <div class="todo-pill done"><div class="todo-check"><i data-lucide="check" style="width:12px;height:12px"></i></div><span>晨间护肤</span></div>
        <div class="todo-pill done"><div class="todo-check"><i data-lucide="check" style="width:12px;height:12px"></i></div><span>早餐记录</span></div>
        <div class="todo-pill"><div class="todo-check"></div><span>晚间瑜伽</span></div>
        <div class="todo-pill"><div class="todo-check"></div><span>背 10 词</span></div>
      </div>
'@
$newTodo = @'
      <div class="todo-grid">
        <div class="todo-pill" data-dom-id="todo-1"><div class="todo-check"></div><span contenteditable="true">点击添加待办</span></div>
        <div class="todo-pill" data-dom-id="todo-2"><div class="todo-check"></div><span contenteditable="true">点击添加待办</span></div>
        <div class="todo-pill" data-dom-id="todo-3"><div class="todo-check"></div><span contenteditable="true">点击添加待办</span></div>
        <div class="todo-pill" data-dom-id="todo-4"><div class="todo-check"></div><span contenteditable="true">点击添加待办</span></div>
      </div>
'@
$c = $c.Replace($oldTodo, $newTodo)

# 6. 清空模块 hint
$c = $c.Replace('>3 餐</span>', '>待记录</span>')
$c = $c.Replace('>1 次</span>', '>待记录</span>')
$c = $c.Replace('>0 kcal</span>', '>待记录</span>')
$c = $c.Replace('>2 次/周</span>', '>待记录</span>')
$c = $c.Replace('>¥86</span>', '>待记录</span>')
$c = $c.Replace('>-1.15%</span>', '>待更新</span>')
$c = $c.Replace('>5 天</span>', '>待记录</span>')
$c = $c.Replace('>今日开心</span>', '>待选择</span>')

# 7. 清空最近动态
$idx1 = $c.IndexOf("<div class=`"card`">`r`n      <div class=`"card-title`"><span class=`"icon-dot`" style=`"--module-color:var(--purple-500)`"></span>最近动态</div>")
if ($idx1 -lt 0) {
    $idx1 = $c.IndexOf("<div class=`"card`">`n      <div class=`"card-title`"><span class=`"icon-dot`" style=`"--module-color:var(--purple-500)`"></span>最近动态</div>")
}
$idx2 = $c.IndexOf("  </main>", $idx1)
if ($idx1 -gt 0 -and $idx2 -gt $idx1) {
    $newActivity = @'
    <div class="card">
      <div class="card-title"><span class="icon-dot" style="--module-color:var(--purple-500)"></span>最近动态</div>
      <div class="activity-list empty-state">
        <div class="activity-item" style="justify-content:center;color:var(--ink-3);font-size:13px;padding:18px 0">
          今天还没有记录，去各模块添加第一条吧 ✨
        </div>
      </div>
    </div>
'@
    $c = $c.Substring(0, $idx1) + $newActivity + "`n" + $c.Substring($idx2)
}

# 8. 替换 script
$oldScript = '<script>lucide.createIcons();</script>'
$newScript = @'
<script>
  lucide.createIcons();

  // 今日心情选择
  document.querySelectorAll('.mood-btn').forEach(function(btn){
    btn.addEventListener('click', function(){
      document.querySelectorAll('.mood-btn').forEach(function(b){ b.classList.remove('selected'); });
      btn.classList.add('selected');
      var emoji = btn.querySelector('.mood-emoji').textContent;
      var moodVal = document.getElementById('mood-stat');
      if(moodVal) moodVal.textContent = emoji;
    });
  });

  // 待办打卡勾选
  document.querySelectorAll('.todo-pill').forEach(function(pill){
    pill.addEventListener('click', function(e){
      if(e.target.isContentEditable) return;
      pill.classList.toggle('done');
      var check = pill.querySelector('.todo-check');
      if(pill.classList.contains('done')){
        check.innerHTML = '<i data-lucide="check" style="width:12px;height:12px"></i>';
      } else {
        check.innerHTML = '';
      }
      lucide.createIcons();
    });
  });
</script>
'@
$c = $c.Replace($oldScript, $newScript)

# 9. 添加心情面板样式
$oldStyle = '.app-frame{display:flex;width:100%;max-width:480px;margin:0 auto;min-height:100vh;padding-top:env(safe-area-inset-top);padding-bottom:env(safe-area-inset-bottom)}'
$styleAdd = @'
      .mood-card{background:linear-gradient(135deg,var(--purple-100) 0%,var(--pink-50) 100%)}
      .mood-subtitle{font-size:12px;color:var(--ink-2);margin:-6px 0 12px 2px}
      .mood-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-bottom:12px}
      .mood-btn{display:flex;flex-direction:column;align-items:center;gap:5px;padding:10px 4px;border-radius:14px;border:1px solid transparent;background:var(--surface);box-shadow:var(--shadow-1);cursor:pointer;transition:transform .1s,box-shadow .15s,border-color .15s}
      .mood-btn:active{transform:scale(.96)}
      .mood-btn.selected{border-color:var(--c-mood);box-shadow:0 0 0 2px var(--purple-100),var(--shadow-2);background:var(--purple-50)}
      .mood-emoji{font-size:26px;line-height:1}
      .mood-name{font-size:11px;color:var(--ink-2)}
      .mood-btn.selected .mood-name{color:var(--ink);font-weight:600}
      .mood-note-wrap{margin-top:4px}
      .mood-note{width:100%;border-radius:var(--r-md);border:1px solid var(--line);padding:10px 12px;font-size:13px;background:var(--surface);color:var(--ink);resize:vertical;min-height:60px;font-family:inherit}
      .todo-pill span[contenteditable]{outline:none;border-bottom:1px dashed var(--line)}
      .todo-pill span[contenteditable]:focus{border-bottom-color:var(--c-home)}
'@
$c = $c.Replace($oldStyle, $oldStyle + "`n" + $styleAdd)

[System.IO.File]::WriteAllText($fp, $c, (New-Object System.Text.UTF8Encoding $false))
Write-Output "home.html updated ($($c.Length) chars)"
