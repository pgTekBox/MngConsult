
(function(){
  var d=document.getElementById('gd-dlg');if(!d||!d.showModal)return;
  var T=new Date(2027,0,1,0,0,0).getTime(),tm=null;
  function pad(n){return n<10?'0'+n:''+n;}
  function tick(){var r=Math.max(0,T-Date.now()),s=Math.floor(r/1000);
    document.getElementById('gd-d').textContent=Math.floor(s/86400);
    document.getElementById('gd-hh').textContent=pad(Math.floor(s%86400/3600));
    document.getElementById('gd-m').textContent=pad(Math.floor(s%3600/60));
    document.getElementById('gd-s').textContent=pad(s%60);}
  function mark(){try{sessionStorage.setItem('60s-gd','1');}catch(e){}}
  function open(){if(d.open)return;tick();clearInterval(tm);tm=setInterval(tick,1000);d.showModal();}
  var ph=null;
  function step(n){document.getElementById('gd-step1').hidden=n!==1;document.getElementById('gd-step2').hidden=n!==2;d.classList.toggle('wide',n===2);d.scrollTop=0;}
  function formIn(){var f=document.getElementById('signup');if(!f||f.closest('#gd-dlg'))return;ph=document.createComment('signup');f.parentNode.insertBefore(ph,f);document.getElementById('gd-slot').appendChild(f);}
  function formOut(){var f=document.getElementById('signup');if(f&&ph&&ph.parentNode&&f.closest('#gd-dlg')){ph.parentNode.insertBefore(f,ph);}if(ph&&ph.parentNode)ph.parentNode.removeChild(ph);ph=null;}
  function close(){clearInterval(tm);mark();if(d.open)d.close();}
  d.addEventListener('close',function(){clearInterval(tm);mark();formOut();step(1);});
  document.getElementById('gd-x2').addEventListener('click',close);
  document.getElementById('gd-back').addEventListener('click',function(){formOut();step(1);document.getElementById('gd-go').focus();});
  d.addEventListener('click',function(e){if(e.target===d)close();});
  document.getElementById('gd-x').addEventListener('click',close);
  document.getElementById('gd-later').addEventListener('click',close);
  document.getElementById('gd-go').addEventListener('click',function(){formIn();step(2);var f=document.getElementById('s-name');if(f)setTimeout(function(){try{f.focus();}catch(e){}},50);});
  d.addEventListener('click',function(e){var a=e.target.closest&&e.target.closest('a[href^="#note-"]');if(a)close();});
  function hit(e){var b=e.target.closest&&e.target.closest('.hero-launch');if(!b)return;if(e.type==='keydown'&&e.key!=='Enter'&&e.key!==' ')return;e.preventDefault();open();}
  document.addEventListener('click',hit);document.addEventListener('keydown',hit);
  window.GrandDepart={open:open};
  var seen=false;try{seen=sessionStorage.getItem('60s-gd')==='1';}catch(e){}
  if(!seen&&Date.now()<T)setTimeout(function(){if(!document.querySelector('dialog[open]'))open();},1200);
})();
