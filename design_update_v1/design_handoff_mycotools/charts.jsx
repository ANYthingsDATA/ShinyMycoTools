// charts.jsx — SVG chart primitives for MycoTools Dashboard
// ANYthings × Mycoteam — NASA/NYCTA modernist aesthetic

const CC = {
  black:'#1A1A1A', white:'#FFFFFF', red:'#E03C31', blue:'#0B3D91',
  charcoal:'#333333', steel:'#555555', midGrey:'#767676',
  lightGrey:'#D9D9D9', nearWhite:'#F5F5F5', offWhite:'#FAFAFA',
  teal:'#57A19F', green:'#00933C', orange:'#FF6319',
  purple:'#6E267B', amber:'#FCCC0A',
  s: ['#0B3D91','#E03C31','#00933C','#FF6319','#6E267B'],
  risk: v => v >= 1 ? '#C62828' : v >= 0.5 ? '#FDD835' : v >= 0.25 ? '#81C784' : v > 0 ? '#2E7D32' : '#E8F5E9',
};

// ── Line Chart ────────────────────────────────────────────────────────────────
function SVGLineChart({ data, sensors, variable, varLabel, width=760, height=280 }) {
  const [tip, setTip] = React.useState(null);
  const PAD = { t:16, r:20, b:52, l:54 };
  const W = width - PAD.l - PAD.r, H = height - PAD.t - PAD.b;

  const dates = React.useMemo(() => [...new Set(data.map(r => r.date))].sort(), [data]);
  const filtered = React.useMemo(() => data.filter(r => sensors.includes(r.sensor)), [data, sensors]);

  if (!dates.length) return (
    <svg width="100%" viewBox={`0 0 ${width} ${height}`}>
      <text x={width/2} y={height/2} textAnchor="middle" fontSize={12} fill={CC.midGrey} fontFamily="'Inter',sans-serif">No data</text>
    </svg>
  );

  const allVals = filtered.map(r => r[variable]).filter(v => v != null);
  const yMin = Math.floor(Math.min(...allVals) * 0.95);
  const yMax = Math.ceil(Math.max(...allVals) * 1.05);
  const yRng = yMax - yMin || 1;

  const xs = i => (i / Math.max(dates.length - 1, 1)) * W;
  const ys = v => H - ((v - yMin) / yRng) * H;

  const yTicks = Array.from({length:5},(_,i) => yMin + (yRng * i / 4));
  const xTicks = dates.filter((_,i) => i % Math.ceil(dates.length/8) === 0 || i === dates.length-1);

  const paths = sensors.map((s,si) => {
    const pts = dates.map((d,di) => {
      const row = filtered.find(r => r.date===d && r.sensor===s);
      return row && row[variable] != null ? `${xs(di).toFixed(1)},${ys(row[variable]).toFixed(1)}` : null;
    });
    // split into segments on nulls
    const segs = []; let cur = [];
    pts.forEach(p => { if(p) cur.push(p); else { if(cur.length) segs.push(cur); cur=[]; } });
    if(cur.length) segs.push(cur);
    return { s, color:CC.s[si%CC.s.length], segs };
  });

  const handleMove = e => {
    const svg = e.currentTarget;
    const rect = svg.getBoundingClientRect();
    const vbW = width, vbH = height;
    const scaleX = vbW / rect.width;
    const mx = (e.clientX - rect.left) * scaleX - PAD.l;
    const idx = Math.round((mx / W) * (dates.length - 1));
    if(idx < 0 || idx >= dates.length) return setTip(null);
    const date = dates[idx];
    const vals = sensors.map((s,si) => {
      const row = filtered.find(r => r.date===date && r.sensor===s);
      return { s, v: row?.[variable], color:CC.s[si%CC.s.length] };
    });
    setTip({ date, vals, x: xs(idx) });
  };

  const tipX = tip ? Math.min(tip.x + 8, W - 145) : 0;

  return (
    <svg width="100%" viewBox={`0 0 ${width} ${height}`}
      onMouseMove={handleMove} onMouseLeave={()=>setTip(null)}
      style={{display:'block',overflow:'visible'}}>
      <g transform={`translate(${PAD.l},${PAD.t})`}>
        {/* Grid */}
        {yTicks.map((v,i) => (
          <line key={i} x1={0} x2={W} y1={ys(v)} y2={ys(v)} stroke={CC.lightGrey} strokeWidth={0.5}/>
        ))}
        {/* Y labels */}
        {yTicks.map((v,i) => (
          <text key={i} x={-6} y={ys(v)+4} textAnchor="end" fontSize={9} fill={CC.midGrey}
            fontFamily="'JetBrains Mono',monospace">{v.toFixed(1)}</text>
        ))}
        {/* X labels */}
        {xTicks.map(d => {
          const di = dates.indexOf(d);
          return <text key={d} x={xs(di)} y={H+18} textAnchor="middle" fontSize={9}
            fill={CC.midGrey} fontFamily="'Inter',sans-serif">{d.slice(5)}</text>;
        })}
        {/* Axes */}
        <line x1={0} x2={0} y1={0} y2={H} stroke={CC.charcoal} strokeWidth={1}/>
        <line x1={0} x2={W} y1={H} y2={H} stroke={CC.charcoal} strokeWidth={1}/>
        {/* Lines */}
        {paths.map(p => p.segs.map((seg,si) => (
          <polyline key={`${p.s}-${si}`} points={seg.join(' ')}
            fill="none" stroke={p.color} strokeWidth={1.75} strokeLinejoin="round" strokeLinecap="round"/>
        )))}
        {/* Crosshair */}
        {tip && <line x1={tip.x} x2={tip.x} y1={0} y2={H} stroke={CC.steel} strokeWidth={1} strokeDasharray="3,3"/>}
        {/* Tooltip */}
        {tip && (
          <g transform={`translate(${tipX},4)`}>
            <rect width={140} height={tip.vals.length*17+26} fill={CC.white} stroke={CC.lightGrey} strokeWidth={1}/>
            <text x={8} y={16} fontSize={9} fontWeight={700} fill={CC.steel}
              fontFamily="'Inter',sans-serif">{tip.date}</text>
            {tip.vals.map(({s,v,color},i) => (
              <text key={s} x={8} y={30+i*17} fontSize={10} fill={color}
                fontFamily="'JetBrains Mono',monospace">
                {s.split(' ')[0]}: {v!=null?v.toFixed(2):'—'}
              </text>
            ))}
          </g>
        )}
      </g>
      {/* Y axis label */}
      <text transform={`rotate(-90) translate(${-(PAD.t+H/2)},13)`} textAnchor="middle"
        fontSize={9} fill={CC.midGrey} fontFamily="'Inter',sans-serif">{varLabel}</text>
      {/* Legend */}
      <g transform={`translate(${PAD.l},${height-8})`}>
        {sensors.map((s,i) => (
          <g key={s} transform={`translate(${i*130},0)`}>
            <line x1={0} x2={16} y1={-2} y2={-2} stroke={CC.s[i%CC.s.length]} strokeWidth={2}/>
            <text x={20} y={2} fontSize={9} fill={CC.charcoal} fontFamily="'Inter',sans-serif">{s}</text>
          </g>
        ))}
      </g>
    </svg>
  );
}

// ── Heatmap ───────────────────────────────────────────────────────────────────
function SVGHeatmap({ data, sensors, indexKey, indexLabel, width=760, height=180 }) {
  const [tip, setTip] = React.useState(null);
  const PAD = { t:8, r:20, b:44, l:100 };
  const W = width - PAD.l - PAD.r, H = height - PAD.t - PAD.b;

  const dates = React.useMemo(() => [...new Set(data.map(r => r.date))].sort(), [data]);
  const cellW = W / Math.max(dates.length,1);
  const cellH = H / Math.max(sensors.length,1);

  const xTicks = dates.filter((_,i) => i % Math.ceil(dates.length/10) === 0 || i === dates.length-1);

  return (
    <svg width="100%" viewBox={`0 0 ${width} ${height}`} style={{display:'block',overflow:'visible'}}>
      <g transform={`translate(${PAD.l},${PAD.t})`}>
        {sensors.map((s,si) =>
          dates.map((d,di) => {
            const row = data.find(r => r.date===d && r.sensor===s);
            const val = row?.[indexKey] ?? null;
            return (
              <rect key={`${s}-${d}`}
                x={di*cellW} y={si*cellH}
                width={Math.max(cellW-0.5,0.5)} height={Math.max(cellH-0.5,0.5)}
                fill={CC.risk(val ?? -1)}
                onMouseEnter={()=>setTip({d,s,val,x:di*cellW,y:si*cellH})}
                onMouseLeave={()=>setTip(null)}
                style={{cursor:'crosshair'}}
              />
            );
          })
        )}
        {/* Sensor labels */}
        {sensors.map((s,si) => (
          <text key={s} x={-6} y={si*cellH+cellH/2+4} textAnchor="end"
            fontSize={10} fill={CC.charcoal} fontFamily="'Inter',sans-serif">{s}</text>
        ))}
        {/* Date labels */}
        {xTicks.map(d => {
          const di = dates.indexOf(d);
          return <text key={d} x={di*cellW+cellW/2} y={H+14} textAnchor="middle"
            fontSize={9} fill={CC.midGrey} fontFamily="'Inter',sans-serif">{d.slice(5)}</text>;
        })}
        {/* Border */}
        <rect x={0} y={0} width={W} height={H} fill="none" stroke={CC.lightGrey} strokeWidth={1}/>
        {/* Tooltip */}
        {tip && (() => {
          const tx = Math.min(tip.x + cellW + 4, W - 144);
          const ty = Math.max(0, tip.y - 4);
          return (
            <g transform={`translate(${tx},${ty})`}>
              <rect width={140} height={52} fill={CC.white} stroke={CC.lightGrey}/>
              <text x={8} y={16} fontSize={10} fontWeight={700} fill={CC.charcoal}
                fontFamily="'Inter',sans-serif">{tip.s}</text>
              <text x={8} y={30} fontSize={9} fill={CC.steel}
                fontFamily="'Inter',sans-serif">{tip.d} · {indexLabel}</text>
              <text x={8} y={46} fontSize={12} fontWeight={700}
                fill={CC.risk(tip.val??-1)} fontFamily="'JetBrains Mono',monospace">
                {tip.val!=null?tip.val.toFixed(2):'—'}
              </text>
            </g>
          );
        })()}
      </g>
      {/* Risk legend */}
      <g transform={`translate(${PAD.l},${height-10})`}>
        {[['No risk','#E8F5E9'],['Low (0.25)','#2E7D32'],['Moderate (0.5)','#81C784'],['High (1.0)','#FDD835'],['Critical','#C62828']].map(([l,c],i) => (
          <g key={l} transform={`translate(${i*120},0)`}>
            <rect x={0} y={-8} width={12} height={12} fill={c} stroke={CC.lightGrey} strokeWidth={0.5}/>
            <text x={16} y={4} fontSize={8} fill={CC.steel} fontFamily="'Inter',sans-serif">{l}</text>
          </g>
        ))}
      </g>
    </svg>
  );
}

// ── Histogram ─────────────────────────────────────────────────────────────────
function SVGHistogram({ data, sensors, variable, varLabel, color, width=340, height=200 }) {
  const PAD = {t:12,r:12,b:38,l:42};
  const W = width-PAD.l-PAD.r, H = height-PAD.t-PAD.b;
  const vals = data.filter(r => sensors.includes(r.sensor) && r[variable]!=null).map(r=>r[variable]);
  if(!vals.length) return <svg width="100%" viewBox={`0 0 ${width} ${height}`}/>;
  const mn=Math.min(...vals), mx=Math.max(...vals), rng=mx-mn||1;
  const N=20, bw=rng/N;
  const bins=Array.from({length:N},(_,i)=>({x0:mn+i*bw,x1:mn+(i+1)*bw,c:0}));
  vals.forEach(v=>{const i=Math.min(Math.floor((v-mn)/bw),N-1);bins[i].c++;});
  const maxC=Math.max(...bins.map(b=>b.c));
  const xs=v=>((v-mn)/rng)*W, ys=c=>H-(c/maxC)*H;
  const yTicks=[0,Math.round(maxC/2),maxC];
  return (
    <svg width="100%" viewBox={`0 0 ${width} ${height}`} style={{display:'block'}}>
      <g transform={`translate(${PAD.l},${PAD.t})`}>
        {yTicks.map(c=>(
          <g key={c}>
            <line x1={0} x2={W} y1={ys(c)} y2={ys(c)} stroke={CC.lightGrey} strokeWidth={0.5}/>
            <text x={-4} y={ys(c)+4} textAnchor="end" fontSize={8} fill={CC.midGrey}
              fontFamily="'JetBrains Mono',monospace">{c}</text>
          </g>
        ))}
        {bins.map((b,i)=>(
          <rect key={i} x={xs(b.x0)+0.5} y={ys(b.c)} width={Math.max(xs(b.x1)-xs(b.x0)-1,1)}
            height={H-ys(b.c)} fill={color||CC.blue} opacity={0.85}/>
        ))}
        <line x1={0} x2={0} y1={0} y2={H} stroke={CC.charcoal} strokeWidth={1}/>
        <line x1={0} x2={W} y1={H} y2={H} stroke={CC.charcoal} strokeWidth={1}/>
        {[mn,(mn+mx)/2,mx].map((v,i)=>(
          <text key={i} x={xs(v)} y={H+14} textAnchor="middle" fontSize={8} fill={CC.midGrey}
            fontFamily="'JetBrains Mono',monospace">{v.toFixed(1)}</text>
        ))}
        <text x={W/2} y={H+28} textAnchor="middle" fontSize={9} fill={CC.steel}
          fontFamily="'Inter',sans-serif">{varLabel}</text>
      </g>
    </svg>
  );
}

// ── MIx Grouped Histogram ─────────────────────────────────────────────────────
function SVGMIxHistogram({ data, sensors, width=340, height=200 }) {
  const PAD={t:12,r:12,b:44,l:42};
  const W=width-PAD.l-PAD.r, H=height-PAD.t-PAD.b;
  const idxs=[{k:'mixMold',l:'Mold',c:CC.blue},{k:'mixTemp',l:'Temp',c:CC.orange},{k:'mixWood',l:'Wood',c:CC.green}];
  const bins=[0,0.25,0.5,0.75,1.0];
  const maxC=Math.max(...idxs.map(ix=>{
    const vs=data.filter(r=>sensors.includes(r.sensor)).map(r=>r[ix.k]).filter(v=>v!=null);
    return Math.max(...bins.slice(0,-1).map((_,i)=>vs.filter(v=>v>=bins[i]&&v<bins[i+1]).length));
  }),1);
  const nBins=bins.length-1, barSlotW=W/nBins, bw=barSlotW/idxs.length-1.5;
  const ys=c=>H-(c/maxC)*H;
  return (
    <svg width="100%" viewBox={`0 0 ${width} ${height}`} style={{display:'block'}}>
      <g transform={`translate(${PAD.l},${PAD.t})`}>
        {[0,Math.round(maxC/2),maxC].map(c=>(
          <g key={c}>
            <line x1={0} x2={W} y1={ys(c)} y2={ys(c)} stroke={CC.lightGrey} strokeWidth={0.5}/>
            <text x={-4} y={ys(c)+4} textAnchor="end" fontSize={8} fill={CC.midGrey}
              fontFamily="'JetBrains Mono',monospace">{c}</text>
          </g>
        ))}
        {idxs.map((ix,ii)=>
          bins.slice(0,-1).map((e0,bi)=>{
            const vs=data.filter(r=>sensors.includes(r.sensor)).map(r=>r[ix.k]).filter(v=>v!=null);
            const cnt=vs.filter(v=>v>=e0&&v<bins[bi+1]).length;
            const x=bi*barSlotW + ii*(bw+1.5)+0.5;
            return <rect key={`${ix.k}-${bi}`} x={x} y={ys(cnt)}
              width={bw} height={H-ys(cnt)} fill={ix.c} opacity={0.85}/>;
          })
        )}
        <line x1={0} x2={0} y1={0} y2={H} stroke={CC.charcoal} strokeWidth={1}/>
        <line x1={0} x2={W} y1={H} y2={H} stroke={CC.charcoal} strokeWidth={1}/>
        {bins.slice(0,-1).map((e,i)=>(
          <text key={e} x={i*barSlotW+barSlotW/2} y={H+13} textAnchor="middle"
            fontSize={8} fill={CC.midGrey} fontFamily="'JetBrains Mono',monospace">{e.toFixed(2)}</text>
        ))}
        <text x={W/2} y={H+26} textAnchor="middle" fontSize={9} fill={CC.steel}
          fontFamily="'Inter',sans-serif">MYCOindex (0–1)</text>
      </g>
      <g transform={`translate(${PAD.l+4},${height-6})`}>
        {idxs.map((ix,i)=>(
          <g key={ix.k} transform={`translate(${i*72},0)`}>
            <rect x={0} y={-7} width={11} height={11} fill={ix.c}/>
            <text x={14} y={4} fontSize={8} fill={CC.steel} fontFamily="'Inter',sans-serif">{ix.l}</text>
          </g>
        ))}
      </g>
    </svg>
  );
}

Object.assign(window, { SVGLineChart, SVGHeatmap, SVGHistogram, SVGMIxHistogram, CC });
