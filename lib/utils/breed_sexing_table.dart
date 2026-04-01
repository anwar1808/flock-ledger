/// Breed-specific sexing information injected into the Claude prompt.
class BreedSexingInfo {
  /// 'easy' | 'moderate' | 'hard' | 'very_hard'
  final String difficulty;

  /// Earliest age (weeks) at which visual sexing is reliable for this breed.
  final int earliestReliableWeeks;

  /// True if sex can be determined at hatch by down/feather colour (sex-linked or autosexing).
  final bool sexLinkedAtHatch;

  /// Paragraph injected verbatim into the Claude prompt as breed context.
  final String promptNote;

  const BreedSexingInfo({
    required this.difficulty,
    required this.earliestReliableWeeks,
    required this.promptNote,
    this.sexLinkedAtHatch = false,
  });
}

// ─── Breed table ─────────────────────────────────────────────────────────────
// Keyed by lowercase normalised breed name. Covers common breeds and
// commercial lines. Lookup uses partial/contained matching (same as
// breed_incubation_table.dart).

const Map<String, BreedSexingInfo> _kSexingTable = {

  // ── Sex-linked hybrids (sexable at hatch by colour) ───────────────────────

  'isa brown': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'ISA Brown is a sex-linked hybrid. At hatch: males are white/cream, '
        'females are brown/reddish. If older, standard comb and wattle cues apply '
        'and should be very clear by 6 weeks.',
  ),
  'hy-line': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Hy-Line Browns are sex-linked. At hatch males are white, females are '
        'brown. At 6+ weeks standard visual cues (comb, wattle) are definitive.',
  ),
  'hyline': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Hy-Line Browns are sex-linked. At hatch males are white, females are '
        'brown. At 6+ weeks standard visual cues (comb, wattle) are definitive.',
  ),
  'red star': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Red Star / Golden Comet is a sex-linked cross. Males hatch yellow/white, '
        'females hatch red/brown. At 6+ weeks comb and wattle cues are very clear.',
  ),
  'golden comet': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Golden Comet is sex-linked. Males hatch pale/yellow, females hatch '
        'reddish-brown. Standard visual cues are definitive by 6 weeks.',
  ),
  'black star': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Black Star is sex-linked. At hatch males have a white head spot, '
        'females are all black. Standard cues definitive by 6 weeks.',
  ),
  'welsummer': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Welsummers are partially sex-linked by down colour at hatch — females '
        'have a distinct dark stripe through the eye, males have a more diffuse pattern. '
        'At 6+ weeks males develop a noticeably larger single comb and wattles faster '
        'than most breeds.',
  ),

  // ── Autosexing breeds ─────────────────────────────────────────────────────

  'cream legbar': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Cream Legbar is an autosexing breed. At hatch: females have a dark '
        'chipmunk stripe, males are paler and more uniform. At 6+ weeks the crest '
        'and comb differences are also clear — males develop a larger comb.',
  ),
  'bielefelder': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Bielefelder is an autosexing breed. At hatch females are darker with '
        'a distinct head pattern; males are lighter. At 6+ weeks standard comb and '
        'wattle cues are obvious.',
  ),
  'salmon faverolles': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 3,
    promptNote: 'Salmon Faverolles are visually autosexing from around 3 weeks. '
        'Males develop black breast feathers and darker colouring; females stay '
        'salmon/buff. By 8 weeks the colour difference is unmistakable. Comb and '
        'wattle cues are secondary but also helpful.',
  ),
  'faverolles': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 3,
    promptNote: 'Salmon Faverolles are visually autosexing from around 3 weeks. '
        'Males develop black breast feathers; females stay salmon/buff. '
        'Colour difference is unmistakable by 8 weeks.',
  ),

  // ── Commercial broilers ───────────────────────────────────────────────────

  'hubbard': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 5,
    promptNote: 'Hubbard broiler crosses: by 6–8 weeks males are noticeably larger '
        'and heavier than females — body size difference alone is a strong cue. '
        'Males also develop a visibly larger, pinker comb earlier. If line information '
        'is provided (e.g. JA87, F15, Flex): all standard Hubbard lines follow the '
        'same fast-growing pattern. Confidence should be HIGH at 6+ weeks.',
  ),
  'ross': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 5,
    promptNote: 'Ross 308/308AP broilers: males grow significantly faster and are '
        'visibly larger-framed than females by 5–6 weeks. Comb development in males '
        'is also earlier. Body size difference is the most reliable cue at this age. '
        'Confidence should be HIGH at 6+ weeks.',
  ),
  'cobb': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 5,
    promptNote: 'Cobb 500/700 broilers: same fast-growing pattern as Ross. Males are '
        'visibly larger with earlier comb development by 5–6 weeks. '
        'Confidence should be HIGH at 6+ weeks.',
  ),
  'freedom ranger': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Freedom Rangers are slower-growing than Cornish crosses but males '
        'still show clear comb and wattle development by 6–8 weeks, plus a larger '
        'body frame. Standard visual cues are reliable.',
  ),
  'cornish cross': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 5,
    promptNote: 'Cornish Cross broilers: males are substantially larger than females '
        'by 5 weeks — body size is the primary cue. Comb development in males is '
        'also earlier. Confidence should be HIGH at 5+ weeks.',
  ),
  'cornish': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Cornish (pure breed): pea comb develops more slowly than single-comb '
        'breeds but body size difference and wattle development are clear by 6–8 weeks. '
        'For Cornish Cross broilers, males are substantially larger by 5 weeks.',
  ),

  // ── Standard single-comb breeds (easy, reliable by 6-8 weeks) ────────────

  'rhode island red': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Rhode Island Reds: males develop a noticeably larger, redder single '
        'comb and wattles by 6–8 weeks. Males are also deeper mahogany in colour '
        'than females. Standard visual cues are highly reliable for this breed.',
  ),
  'rir': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Rhode Island Reds: males develop a noticeably larger, redder single '
        'comb and wattles by 6–8 weeks. Males are also deeper mahogany in colour. '
        'Standard cues are highly reliable.',
  ),
  'leghorn': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 5,
    promptNote: 'Leghorns: males develop a large floppy single comb very early — '
        'often visible by 5 weeks. Comb and wattle development is one of the fastest '
        'of any breed. Confidence should be HIGH at 6+ weeks.',
  ),
  'australorp': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Australorps: males develop comb and wattles noticeably faster than '
        'females and are larger-framed. The black-green sheen is present in both '
        'sexes, so colour is not a useful cue — rely on comb, wattle, and body size.',
  ),
  'black australorp': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Black Australorps: rely on comb size, wattle development, and body '
        'frame — colour is not a useful cue as both sexes are black with green sheen. '
        'Standard cues are clear by 6–8 weeks.',
  ),
  'sussex': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Sussex (Light, Speckled, etc.): standard single comb and wattle '
        'development is clear by 6–8 weeks. Males also tend to be larger-framed. '
        'Light Sussex: males may show earlier hackle striping.',
  ),
  'light sussex': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Light Sussex: reliable by 6–8 weeks. Males develop larger comb and '
        'wattles, and may show early hackle striping with darker centres. '
        'Body frame is also larger.',
  ),
  'new hampshire': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'New Hampshire Reds: single comb develops quickly in males, visible '
        'by 6 weeks along with early wattle development. Body size difference is '
        'also pronounced. Reliable standard visual cues.',
  ),
  'new hampshire red': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'New Hampshire Reds: single comb and wattles develop quickly in males. '
        'Reliable by 6–8 weeks.',
  ),
  'barnevelder': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Barnevelders: males develop larger comb and wattles by 6–8 weeks. '
        'The double-laced pattern in females becomes visible as feathering develops — '
        'males have less distinct lacing. Both colour and comb cues apply.',
  ),
  'marans': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 7,
    promptNote: 'Marans (Black Copper, Cuckoo, etc.): comb and wattle development is '
        'reliable but slightly slower than some breeds — assess at 7–8 weeks for '
        'best accuracy. Cuckoo Marans: males have lighter, less distinct barring '
        'than females (same principle as Barred Rocks).',
  ),
  'black copper marans': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 7,
    promptNote: 'Black Copper Marans: males develop larger comb and wattles with '
        'more copper hackle colouring by 7–8 weeks. Females have finer copper '
        'markings. Standard cues reliable from 7 weeks.',
  ),

  // ── Barred breeds (barring sex-linkage) ───────────────────────────────────

  'barred rock': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 0,
    sexLinkedAtHatch: true,
    promptNote: 'Barred Plymouth Rocks: at hatch, males have a larger, more diffuse '
        'white head spot; females have a smaller, sharper spot. At 6+ weeks males '
        'also show lighter, wider barring than females (the barring gene is '
        'sex-linked) AND develop a larger comb. Both cues confirm sex.',
  ),
  'plymouth rock': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Plymouth Rocks (Barred variety): males show lighter, wider barring '
        'than females due to the sex-linked barring gene. Males also develop a '
        'larger single comb by 6–8 weeks. Two independent cues available.',
  ),
  'dominique': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 7,
    promptNote: 'Dominiques have a rose comb which develops more slowly than single '
        'combs, making early assessment harder. Males show lighter, wider cuckoo '
        'barring (sex-linked) and a larger body frame by 7–8 weeks. '
        'Focus on barring width and body size rather than comb.',
  ),

  // ── Rose-comb and pea-comb breeds (moderate) ──────────────────────────────

  'wyandotte': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Wyandottes have a rose comb that develops more slowly and less '
        'dramatically than single combs — do not rely on comb alone. '
        'Focus on wattle development, body size, and feather texture. '
        'Males may show early saddle/hackle point feathering by 8–10 weeks. '
        'Reliable from 8 weeks.',
  ),
  'orpington': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Orpingtons: the heavy, fluffy plumage can partially obscure comb '
        'and wattle development, making visual sexing slightly harder than leaner '
        'breeds. Focus on comb colour and size, wattle presence, and body frame — '
        'males are noticeably blockier. Reliable from 8 weeks.',
  ),
  'buff orpington': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Buff Orpingtons: fluffy plumage can obscure comb. Focus on comb '
        'redness and size, wattle buds, and body frame. Males are blockier. '
        'Reliable from 8 weeks.',
  ),
  'brahma': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 10,
    promptNote: 'Brahmas have a pea comb and heavy feathered feet, both of which '
        'slow down reliable visual sexing. The pea comb develops very subtly — '
        'do not use it as a primary cue before 10 weeks. Focus on body size '
        '(males are substantially larger), hackle feather shape (pointed in males), '
        'and any early saddle feather development. Reliable from 10–12 weeks.',
  ),
  'cochin': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 10,
    promptNote: 'Cochins: heavily feathered legs and fluffy body plumage make visual '
        'sexing harder. The single comb is useful but hidden by feathering at young '
        'ages. Focus on body size and hackle feather shape. Males develop pointed '
        'hackle feathers visible by 10 weeks. Reliable from 10–12 weeks.',
  ),
  'jersey giant': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 7,
    promptNote: 'Jersey Giants: slow-maturing but males develop noticeably larger '
        'combs, wattles, and body frames by 7–8 weeks. Body size difference is '
        'especially pronounced given the breed\'s large overall size.',
  ),
  'ameraucana': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Ameraucanas have a pea comb which develops more slowly than single '
        'combs. Do not rely on comb size alone before 8 weeks. Use body size, '
        'wattle development (males get small wattles by 8 weeks), and feather '
        'texture (males develop pointed hackle feathers). Reliable from 8–10 weeks.',
  ),
  'araucana': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Araucanas have a pea comb and may be tufted, making visual sexing '
        'slightly harder. Focus on body size, wattle development, and hackle '
        'feather shape. Reliable from 8–10 weeks.',
  ),
  'easter egger': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Easter Eggers vary widely as they are mixed-heritage birds. Most '
        'have a pea comb (slower to develop) but body size and feather texture are '
        'reliable from 8 weeks. Some lines may show comb differences earlier.',
  ),

  // ── Hard to sex ───────────────────────────────────────────────────────────

  'silkie': BreedSexingInfo(
    difficulty: 'very_hard',
    earliestReliableWeeks: 16,
    promptNote: 'Silkies are notoriously difficult to sex visually and are considered '
        'one of the hardest breeds. The walnut (mulberry) comb is barely visible '
        'under the crest, and the fluffy silk feathering hides body shape. '
        'Even experienced breeders often cannot confirm sex until 4–6 months when '
        'crowing, egg-laying, or streamered crest feathers in males become apparent. '
        'Be honest — low or medium confidence is expected and appropriate before '
        '16 weeks. Do not commit to high confidence.',
  ),
  'silky': BreedSexingInfo(
    difficulty: 'very_hard',
    earliestReliableWeeks: 16,
    promptNote: 'Silkies are notoriously difficult to sex — see Silkie note. '
        'Honest low/medium confidence before 16 weeks is appropriate.',
  ),
  'polish': BreedSexingInfo(
    difficulty: 'hard',
    earliestReliableWeeks: 12,
    promptNote: 'Polish chickens: the large crest obscures the comb, making it '
        'difficult to assess early on. Males develop a wilder, more irregular crest '
        'shape (less round/neat than females) and larger wattles by 10–12 weeks. '
        'Females keep a neat rounded crest. Crest shape is the primary cue — '
        'not comb. Reliable from 12 weeks.',
  ),
  'sebright': BreedSexingInfo(
    difficulty: 'very_hard',
    earliestReliableWeeks: 14,
    promptNote: 'Sebrights are hen-feathered — cockerels lack the pointed hackle and '
        'saddle feathers typical of males in other breeds. This makes visual sexing '
        'very difficult as the most reliable feather cue is absent. Rely on comb '
        'and wattle development (males still develop larger comb/wattles) and body '
        'posture. Low or medium confidence before 14 weeks is appropriate.',
  ),
  'hamburg': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Hamburgs have a rose comb which slows visual sexing slightly. '
        'Focus on wattle development and body size. Males develop small but visible '
        'wattles and a larger rose comb by 8 weeks.',
  ),
  'ancona': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Anconas: single comb develops quickly in males, similar to Leghorns. '
        'Reliable from 6 weeks using standard comb, wattle, and body size cues.',
  ),
  'minorca': BreedSexingInfo(
    difficulty: 'easy',
    earliestReliableWeeks: 6,
    promptNote: 'Minorcas: large single comb develops early and prominently in males. '
        'One of the easier breeds to sex by 6 weeks.',
  ),
  'langshan': BreedSexingInfo(
    difficulty: 'moderate',
    earliestReliableWeeks: 8,
    promptNote: 'Langshans: standard single comb cues apply but the breed matures '
        'relatively slowly. Reliable from 8 weeks using comb, wattle, and the '
        'notably upright posture and larger body frame in males.',
  ),
};

// ─── Lookup ───────────────────────────────────────────────────────────────────

/// Returns breed-specific sexing info for [breed], or null if not in the table.
/// Case-insensitive; uses partial/contained matching as a fallback.
BreedSexingInfo? lookupBreedSexingInfo(String breed) {
  final key = breed.toLowerCase().trim();
  if (_kSexingTable.containsKey(key)) return _kSexingTable[key];
  for (final entry in _kSexingTable.entries) {
    if (key.contains(entry.key) || entry.key.contains(key)) {
      return entry.value;
    }
  }
  return null;
}
