import 'dotenv/config';
import mongoose from 'mongoose';

const paddleSchema = new mongoose.Schema({
  id: { type: String, unique: true }, name: String, power: Number, control: Number,
  spin: Number, price: Number, rarity: String
});
const characterStyleSchema = new mongoose.Schema({
  name: { type: String, unique: true }, outfitPrimary: String,
  outfitSecondary: String, speedMultiplier: Number
});
const Paddle = mongoose.model('Paddle', paddleSchema);
const CharacterStyle = mongoose.model('CharacterStyle', characterStyleSchema);

const paddles = [
  { id: 'starter_paddle', name: 'Street Woodie', power: 40, control: 60, spin: 30, price: 0, rarity: 'common' },
  { id: 'onix_z5', name: 'Onix Graphite Z5', power: 71, control: 72, spin: 49, price: 250, rarity: 'common' },
  { id: 'head_radical_pro', name: 'HEAD Radical Pro', power: 69, control: 76, spin: 66, price: 300, rarity: 'common' },
  { id: 'paddletek_ts5', name: 'Paddletek Bantam TS-5', power: 73, control: 68, spin: 59, price: 350, rarity: 'common' },
  { id: 'franklin_ben_johns', name: 'Franklin Ben Johns 16mm', power: 69, control: 71, spin: 66, price: 400, rarity: 'common' },
  { id: 'crbn_genesis_1', name: 'CRBN TruFoam Genesis 1', power: 74, control: 56, spin: 89, price: 450, rarity: 'common' },
  { id: 'vatic_prism_flash', name: 'Vatic Pro Prism Flash 16mm', power: 65, control: 76, spin: 83, price: 600, rarity: 'rare' },
  { id: 'engage_pursuit_maxx', name: 'Engage Pursuit MAXX MX 6.0', power: 70, control: 75, spin: 66, price: 750, rarity: 'rare' },
  { id: 'engage_pursuit_graphite', name: 'Engage Pursuit MX 6.0', power: 69, control: 74, spin: 69, price: 800, rarity: 'rare' },
  { id: 'crbn_genesis_2', name: 'CRBN TruFoam Genesis 2', power: 71, control: 72, spin: 86, price: 900, rarity: 'rare' },
  { id: 'crbn_waves_1', name: 'CRBN TruFoam Waves 1', power: 78, control: 59, spin: 86, price: 950, rarity: 'rare' },
  { id: 'ronbus_r1_nova', name: 'Ronbus R1 Nova', power: 72, control: 65, spin: 86, price: 1100, rarity: 'rare' },
  { id: 'gearbox_cx14e', name: 'Gearbox CX14E Ultimate Power', power: 81, control: 62, spin: 80, price: 1250, rarity: 'rare' },
  { id: 'selkirk_luxx_invikta', name: 'Selkirk LUXX Control Air', power: 59, control: 79, spin: 86, price: 1400, rarity: 'rare' },
  { id: 'joola_perseus_pro_4', name: 'JOOLA Perseus Pro IV 16mm', power: 80, control: 65, spin: 84, price: 1800, rarity: 'legendary' },
  { id: 'joola_perseus_pro_5', name: 'JOOLA Perseus Pro V 16mm', power: 77, control: 67, spin: 90, price: 2200, rarity: 'legendary' },
  { id: 'honolulu_j6cr', name: 'Honolulu J6CR Crystal Blue', power: 78, control: 67, spin: 95, price: 2400, rarity: 'legendary' },
  { id: 'honolulu_j6nf', name: 'Honolulu J6NF Endurance', power: 77, control: 71, spin: 90, price: 2500, rarity: 'legendary' },
  { id: 'selkirk_power_air', name: 'Selkirk Vanguard Power Air', power: 81, control: 56, spin: 90, price: 2800, rarity: 'legendary' },
  { id: 'sixzero_black_opal', name: 'Six Zero Black Opal', power: 85, control: 59, spin: 88, price: 3200, rarity: 'legendary' },
  { id: 'sixzero_coral_pro_elongated', name: 'Six Zero Coral Pro Elongated', power: 77, control: 67, spin: 92, price: 3500, rarity: 'legendary' },
  { id: 'sixzero_coral_pro_widebody', name: 'Six Zero Coral Pro Widebody', power: 71, control: 82, spin: 92, price: 3800, rarity: 'legendary' },
  { id: 'diadem_vice', name: 'Diadem VICE (EVA Concept)', power: 70, control: 71, spin: 76, price: 4500, rarity: 'legendary' },
  { id: 'prokennex_black_ace', name: 'ProKennex Kinetic Black Ace', power: 86, control: 56, spin: 83, price: 5200, rarity: 'legendary' },
  { id: 'joola_mod_ta15', name: 'JOOLA Perseus Mod TA-15 (Banned)', power: 86, control: 61, spin: 90, price: 6000, rarity: 'legendary' }
];
const characterStyles = [
  { name: 'Neon Rebel', outfitPrimary: '#FACC15', outfitSecondary: '#DC2626', speedMultiplier: 1.0 },
  { name: 'Cyber Dinker', outfitPrimary: '#38BDF8', outfitSecondary: '#818CF8', speedMultiplier: 1.1 }
];

await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/pickleball_app');
await Paddle.deleteMany({ id: { $in: ['carbon_pro', 'titanium_edge'] } });
await Promise.all(paddles.map((paddle) => Paddle.updateOne(
  { id: paddle.id }, { $set: paddle }, { upsert: true }
)));
await Promise.all(characterStyles.map((style) => CharacterStyle.updateOne(
  { name: style.name }, { $set: style }, { upsert: true }
)));
console.log(`Seeded ${paddles.length} paddles and ${characterStyles.length} character styles.`);
await mongoose.disconnect();
