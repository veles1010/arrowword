import '../generation/word_entry.dart';

// Authored local content, not a filtered Easy bank or a downloaded dictionary.
// IDs are track + normalized solution; v1 wording/identity is a compatibility contract.
List<WordEntry> _entries(
  String source,
  String track,
  WordDifficulty difficulty,
) {
  final entries = <WordEntry>[];
  for (final line in source.trim().split('\n')) {
    final parts = line.trim().split('|');
    if (parts.length < 2 || parts.length > 3) {
      throw FormatException('Invalid curated $track record.');
    }
    entries.add(
      WordEntry(
        parts[0],
        parts[1],
        id: '$track-${parts[0].toLowerCase()}',
        clueId:
            '${track}_v1_${(entries.length + 1).toString().padLeft(6, '0')}',
        difficulty: parts.length == 3
            ? WordDifficulty.values.byName(parts[2])
            : difficulty,
        tags: [track],
      ),
    );
  }
  return List.unmodifiable(entries);
}

final mediumWords = _entries(_medium, 'medium', WordDifficulty.medium);
final hardWords = _entries(_hard, 'hard', WordDifficulty.hard);

const _medium = '''
ACORN|Meşe ağacının sert kabuklu tohumu
MAPLE|Şurubuyla tanınan dilimli yapraklı ağaç
CEDAR|Kokulu odunuyla tanınan iğne yapraklı ağaç
BIRCH|Beyaz kabuklu ince gövdeli ağaç
WILLOW|Dalları suya doğru sarkan ağaç
BEECH|Düz gri kabuklu orman ağacı
PALM|Dalsız gövdesinde yaprakları tepede toplanan ağaç
BAMBOO|İçi boş boğumlu hızlı büyüyen bitki
CACTUS|Kurak bölgelerde su depolayan dikenli bitki
FERN|Çiçek açmayan parçalı yapraklı bitki
MOSS|Nemli yüzeyleri örten küçük yeşil bitki
CLOVER|Üç yaprakçığıyla tanınan çayır bitkisi
PETAL|Çiçeğin renkli taç yaprağı
POLLEN|Çiçeklerin üremesini sağlayan ince toz
SPROUT|Tohumdan yeni çıkan genç sürgün
ORCHARD|Meyve ağaçlarının birlikte yetiştirildiği alan
MEADOW|Çiçekli otlarla kaplı doğal çayır
PRAIRIE|Kuzey Amerika'nın geniş ve ağaçsız otlakları
GLACIER|Yavaş ilerleyen büyük buz kütlesi
CANYON|Dik yamaçlı derin akarsu vadisi
CLIFF|Denize veya vadiye bakan dik kayalık
SHORE|Denizin karayla buluştuğu bölüm
REEF|Su yüzeyine yakın kaya oluşumu
TIDE|Deniz seviyesinin düzenli yükselip alçalması
DELTA|Akarsuyun ağzında biriken üçgensi düzlük
LAGOON|Denizden dar şeritle ayrılmış kıyı gölü
MARSH|Sazlıklarla kaplı sığ sulak alan
SWAMP|Ağaçların da yetiştiği su basmış alan
BASIN|Akarsuların suyunu topladığı geniş bölge
RIDGE|Dağın uzanan dar sırtı
SUMMIT|Bir dağın en yüksek noktası
CRATER|Yanardağın tepesindeki çanak biçimli açıklık
FOSSIL|Kaya içinde korunmuş eski canlı kalıntısı
MINERAL|Doğada oluşan belirli yapılı katı madde
GRANITE|Benekli görünümlü sert yapı taşı
MARBLE|Damarlı yapısıyla tanınan süsleme taşı
QUARTZ|Saatlerde titreşiminden yararlanılan sert kristal
COPPER|Elektriği iyi ileten kızılımsı metal
SILVER|Takılarda kullanılan parlak beyaz değerli metal
BRONZE|Bakır ve kalay karışımı metal
STEEL|Demire karbon katılarak üretilen alaşım
IRON|Paslanabilen mıknatısın çektiği yaygın metal
ZINC|Demiri paslanmadan korumak için kullanılan metal
NICKEL|Çelik alaşımlarında ve paralarda kullanılan gümüşümsü metal
GOLD|Sarı renkli değerli takı metali
COAL|Yakıt olarak kullanılan siyah tortul madde
JADE|Süs eşyalarında kullanılan yeşil taş
SLATE|Çatılarda ve kara tahtalarda kullanılan katmanlı taş
FLINT|Vurulduğunda kıvılcım çıkarabilen sert taş
CLAY|Islanınca biçim verilebilen ince toprak
OTTER|Suda yüzmeye uyumlu oyuncu memeli
BADGER|Kazıcı pençeli siyah beyaz yüzlü memeli
BEAVER|Baraj yapan yassı kuyruklu kemirgen
FERRET|Uzun gövdeli evcilleştirilmiş küçük sansargil
MOOSE|Geniş yassı boynuzlu iri geyik
BISON|Omuzları yüksek iri yabani sığır
HYENA|Güçlü çeneli gülüşü andıran sesli hayvan
JACKAL|Küçük kurda benzeyen yabani köpekgil
LYNX|Kulak uçları püsküllü yabani kedi
COUGAR|Amerika kıtasındaki tek renkli büyük kedi
GAZELLE|İnce bacaklı hızlı koşan boynuzlu hayvan
SEAL|Yüzgeç ayaklı deniz memelisi
WALRUS|Uzun dişli iri kutup deniz memelisi
PENGUIN|Yüzebilen fakat uçamayan deniz kuşu
PELICAN|Gagasının altında kese bulunan kuş
SPARROW|Yerleşimlerde görülen küçük kahverengi ötücü
RAVEN|Kalın gagalı, iri ve siyah kargagil
CROW|Zeki siyah tüylü yaygın kuş
FINCH|Tohum kırmaya uygun konik gagalı küçük ötücü
HERON|Sığ suda balık bekleyen uzun bacaklı kuş
STORK|Uzun gagalı çatılara yuva yapan kuş
FALCON|Sivri kanatlı hızlı avcı kuş
HAWK|Gündüz avlanan geniş kanatlı yırtıcı kuş
GULL|Kıyılarda yaşayan çoğunlukla beyaz kuş
SALMON|Üremek için akarsuya dönen balık
TROUT|Serin tatlı sularda yaşayan benekli balık
SQUID|Uzun gövdeli dokunaçlı deniz canlısı
OYSTER|İnci yetiştiriciliğinde kullanılan çift kabuklu canlı
SHRIMP|Küçük kıvrık gövdeli deniz kabuklusu
CLAM|Kuma gömülen çift kabuklu deniz canlısı
ANCHOR|Tekneyi yerinde tutan ağır demir
SAIL|Rüzgarla tekneyi ilerleten kumaş yüzey
RUDDER|Teknenin yönünü belirleyen hareketli parça
PADDLE|Küçük tekneyi elle ilerleten kürek
CANOE|İnce uzun açık üstlü kürekli tekne
KAYAK|Çift uçlu kürekle kullanılan dar tekne
FERRY|Yolcu veya araç taşıyan kısa mesafe gemisi
YACHT|Gezi amacıyla kullanılan özel tekne
WAGON|Hayvanların çektiği dört tekerlekli yük arabası
TRAILER|Başka araca bağlanarak çekilen taşıt
ENGINE|Yakıt yakarak pistonları çalıştıran güç düzeneği
MOTOR|Elektriği dönme hareketine çeviren düzenek
CABLE|Elektrik taşıyan yalıtılmış bağlantı hattı
SOCKET|Fişin takıldığı elektrik bağlantı yuvası
PLUG|Elektrik kablosunun prize takılan ucu
SWITCH|Devreyi açıp kapatan kumanda
LAMP|İç mekanda ışık veren eşya
TORCH|Ucunda alev yanan taşınabilir aydınlatıcı
LANTERN|Camlı haznesinde alevi koruyan taşınabilir aydınlatıcı
CHIMNEY|Dumanı yapıdan dışarı taşıyan kanal
PORCH|Evin girişindeki üstü örtülü bölüm
BALCONY|Binadan dışarı uzanan açık platform
ATTIC|Çatının hemen altındaki iç alan
CELLAR|Yapının altında bulunan depolama bölümü
GARAGE|Araçların saklandığı kapalı bölüm
FENCE|Bir alanın sınırını çevreleyen engel
GATE|Çevrili bir alana giriş açıklığı
PATH|Yürüyerek oluşmuş dar geçiş yolu
TUNNEL|Yeraltından geçen kapalı geçit
AVENUE|Genellikle geniş ve ağaçlıklı şehir yolu
ALLEY|Binalar arasındaki dar sokak
SQUARE|Kentte açık toplanma alanı
TOWER|Yüksek ve dar yapı
PALACE|Hükümdarın yaşadığı gösterişli büyük yapı
TEMPLE|Dini törenler için kullanılan yapı
CHAPEL|Küçük Hristiyan ibadet yeri
MOSQUE|Müslümanların topluca ibadet ettiği yapı
SHRINE|Kutsal kabul edilen ziyaret yeri
STATUE|Bir varlığın üç boyutlu tasviri
COLUMN|Gazetede düzenli yayımlanan köşe yazısı
PILLAR|Bir yapıyı destekleyen dik dayanak
ARCH|Açıklık üzerinde kavisli taşıyıcı yapı
DOME|Yarım küre biçimli yapı örtüsü
STAIR|Merdiveni oluşturan tek basamak
LADDER|Taşınabilir basamaklı çıkma aracı
RAIL|Tren tekerleklerinin üzerinde ilerlediği çelik hat
BOLT|Somunla sıkılan metal bağlayıcı
SCREW|Döndürülerek yerleştirilen dişli bağlayıcı
NAIL|Çekiçle çakılan sivri bağlayıcı
CHISEL|Malzemeyi keserek oyan el aleti
CEREAL|Kahvaltıda sütle yenen tahıl ürünü
GINGER|Keskin aromalı kök baharat
NUTMEG|Rendelenerek kullanılan hoş kokulu sert baharat
VANILLA|Tatlılara koku veren tropik bitki ürünü
COCOA|Kavrulmuş çekirdeklerden elde edilen çikolata tozu
CUMIN|Yemeklere katılan keskin kokulu tohum baharat
BASIL|Geniş yapraklı hoş kokulu mutfak otu
THYME|Küçük yapraklı güçlü kokulu baharat bitkisi
MINT|Ferahlatıcı kokulu çaylık yaprak
PARSLEY|Yemeklere katılan parçalı yeşil yaprak
RADISH|Çiğ yenen gevrek keskin kök sebze
TURNIP|Yuvarlak açık renkli kök sebze
CELERY|Sapları ve kökü yenebilen kokulu sebze
LETTUCE|Salatada kullanılan gevrek yapraklı sebze
SPINACH|Pişirilerek de yenen koyu yeşil yaprak
LENTIL|Çorbalarda kullanılan küçük yassı baklagil
BEAN|Uzun kabuk içinde gelişen baklagil tohumu
PLUM|Tek çekirdekli ekşi veya tatlı meyve
LIME|Küçük yeşil ekşi turunçgil
MANGO|Büyük çekirdekli sarı etli tropik meyve
APRON|Giysiyi kirden koruyan ön örtü
RIBBON|Süslemede kullanılan ince kumaş şerit
ZIPPER|Giysi kenarlarını dişlerle birleştiren kapatıcı
COLLAR|Giysinin boynu çevreleyen bölümü
SLEEVE|Giysinin kolu örten bölümü
BELT|Giysiyi belde tutan uzun şerit
BUCKLE|Kayışın ucunu sabitleyen metal parça
SANDAL|Ayağı şeritlerle tutan açık ayakkabı
SLIPPER|Evde giyilen yumuşak ayakkabı
BOOT|Ayağı ve bileği örten ayakkabı
TUNIC|Kalçaya kadar uzanan bol üst giysi
VEST|Üst gövdeyi örten kolsuz giysi
BLOUSE|Genellikle ince kumaşlı kadın üst giysisi
SUIT|Uyumlu ceket ve alt giysi takımı
DENIM|Kot yapımında kullanılan dayanıklı kumaş
LINEN|Keten lifinden dokunan kumaş
VELVET|Yüzeyi kısa yumuşak tüylü kumaş
WOOL|Koyun tüyünden elde edilen tekstil lifi
SILK|Böcek kozasından elde edilen parlak lif
LEATHER|Çanta ve ayakkabıda kullanılan işlenmiş hayvan derisi
ADVICE|Karar vermeye yardımcı olan öneri
ATTEMPT|Başarmak için yapılan ilk veya yeni deneme
BENEFIT|Bir şeyden sağlanan yarar
BUDGET|Gelirin nasıl harcanacağını belirleyen mali plan
CHANCE|Bir sonucun mümkün olma olasılığı
CHOICE|Alternatifler arasında karar verme eylemi
COST|Bir şeyi edinmek için ödenen miktar
DAMAGE|Bir şeye verilen fiziksel zarar
DEGREE|Bir niteliğin düzeyi veya ölçüsü
EFFECT|Bir nedenin başka şeyde yarattığı değişim
EFFORT|Amaç için harcanan güç
ENERGY|İş yapmayı sağlayan kapasite
EVENT|Belirli zamanda gerçekleşen olay
FACT|Doğruluğu kanıtlanmış gerçek bilgi
FAULT|Yanlış sonuca yol açan kusur
HABIT|Sık tekrarla yerleşmiş davranış
IMPACT|Güçlü çarpma veya belirgin etki
INCOME|Düzenli olarak elde edilen para
ISSUE|Tartışılan veya çözülmesi gereken konu
METHOD|Bir işi yapmanın düzenli yolu
OPTION|Karar verirken seçilebilecek yollardan biri
ORIGIN|Bir şeyin başladığı kaynak
PATTERN|Tekrarlanan düzen veya örnek biçim
PURPOSE|Bir eylemin yapılma amacı
REASON|Bir durumu açıklayan gerekçe
RESULT|Yarışma veya işlem sonunda ortaya çıkan durum
ROUTINE|Düzenli tekrarlanan işler bütünü
SIGNAL|Bilgi veren işaret
SUCCESS|İstenen amaca ulaşma durumu
VALUE|Bir şeyin taşıdığı önem veya karşılık
ABSORB|Sıvıyı kendi içine çekmek
ADAPT|Yeni koşullara uyum sağlamak
ADJUST|Bir ayarı küçük değişikliklerle uygunlaştırmak
ADMIRE|Birinin niteliğini beğeniyle karşılamak
ADMIT|Kendi hatasını açıkça kabul etmek
ADOPT|Bir yöntemi kendi uygulaması haline getirmek
ADVISE|Birine ne yapabileceğini önermek
AFFORD|Bir harcamayı karşılayabilecek durumda olmak
AGREE|Aynı görüşte buluşmak
ALLOW|Bir davranışa izin vermek
AMUSE|Birini eğlendirip güldürmek
APPLY|Bir kuralı duruma uyarlayıp kullanmak
ARGUE|Görüş ayrılığı üzerinde tartışmak
AVOID|İstenmeyen durumdan uzak durmak
BEHAVE|Belirli bir biçimde davranmak
BLAME|Birini hatadan sorumlu tutmak
BLEND|Malzemeleri homojen bir karışım haline getirmek
BOIL|Sıvıyı kabarcık çıkarana kadar ısıtmak
BOOST|Bir şeyin gücünü artırmak
BUILD|Parçaları birleştirerek yapı oluşturmak
BURST|Basınçla aniden yarılıp açılmak
CARVE|Malzemeyi keserek şekil vermek
CHASE|Yakalamak için arkasından koşmak
CLAIM|Bir şeyin doğru olduğunu öne sürmek
COLLECT|Pulları veya benzer nesneleri biriktirmek
COMBINE|Ayrı parçaları birlikte kullanmak
COMPARE|Benzerlikleri ve farkları incelemek
COMPETE|Aynı başarı için başkalarıyla yarışmak
CONFIRM|Bilginin doğruluğunu onaylamak
CONNECT|İki şeyi birbirine bağlamak
CONTAIN|Bir şeyi içinde bulundurmak
CONVERT|Başka biçime dönüştürmek
COUNT|Kaç tane olduğunu belirlemek
CREATE|Daha önce olmayan bir şey oluşturmak
DECIDE|Seçenekler arasında karar vermek
DEFEND|Saldırıya karşı korumak
DEFINE|Bir kavramın anlamını açıklamak
DELIVER|Bir şeyi alıcısına ulaştırmak
DEMAND|Güçlü biçimde talep etmek
DEPEND|Başka bir şeye bağlı olmak
DESIGN|Bir şeyin biçimini önceden planlamak
DETECT|Gizli veya zor fark edilen şeyi bulmak
DEVELOP|Zamanla daha ileri hale getirmek
DIVIDE|Bir bütünü parçalara ayırmak
DOUBT|Bir bilginin doğruluğundan emin olmamak
ENJOY|Bir şeyden keyif almak
ENSURE|Bir sonucun gerçekleşmesini güvenceye almak
ESCAPE|Tehlikeli veya kapalı yerden kurtulmak
EXAMINE|Tanı koymak için hastayı dikkatle incelemek
EXIST|Gerçek dünyada var olmak
EXPAND|Hacmini veya kapsamını büyütmek
EXPLAIN|Anlaşılması için nedenlerini anlatmak
EXTEND|Boyunu veya süresini uzatmak
GATHER|Bir buluşma için aynı yerde toplanmak
GUARD|Tehlikeye karşı nöbet tutarak korumak
GUIDE|Birinin yolunu bulmasına yardımcı olmak
HANDLE|Bir işi veya sorunu yönetmek
IMPROVE|Öncekinden daha iyi hale getirmek
INCLUDE|Bir bütüne parça olarak katmak
INTEND|Bir şeyi yapmayı amaçlamak
ACTIVE|Harekette veya faaliyette olan
ACTUAL|Beklenen değil, gerçekte var olan
AWKWARD|Kullanımı zor veya rahat olmayan
BASIC|En temel düzeyde olan
BITTER|Tatlı olmayan keskin acı tada sahip
BRIGHT|Çok ışık yayan veya yansıtan
CALM|Telaşa kapılmadan duygularını dengede tutan
CAREFUL|Hata yapmamak için dikkat gösteren
CASUAL|Resmi olmayan gündelik
CHEAP|Fiyatı düşük olan
CLEAR|İçi görülebilecek kadar saydam
CLEVER|Çözüm bulmakta yaratıcı ve becerikli
COMMON|Birçok yerde sık görülen
CORRECT|Hata içermeyen doğru
CRUEL|Başkalarının acısına aldırmayan
CURIOUS|Yeni şeyleri öğrenmek isteyen
DAMP|Hafifçe nemlenmiş olan
DEEP|Yüzeyden çok aşağıya uzanan
DENSE|Birim alanda sık yerleşmiş olan
DIRECT|Aracı olmadan doğrudan gerçekleşen
EAGER|Bir şeyi yapmak için hevesli
FAIR|Herkese aynı ölçütle yaklaşan
FAMOUS|Birçok kişi tarafından tanınan
FIERCE|Çok güçlü ve saldırgan
FORMAL|Resmi kurallara uygun
FRESH|Yeni ve henüz bozulmamış
GENTLE|Sertlik göstermeyen yumuşak davranışlı
GLOBAL|Bütün dünyayı ilgilendiren
HONEST|Gerçeği gizlemeyen dürüst
HUMBLE|Kendini başkalarından üstün görmeyen
LOCAL|Belirli bir bölgeyle ilgili
LOYAL|Bağlılığını koruyan sadık
MATURE|Gelişimini tamamlamış olgun
MODEST|Başarılarıyla övünmeyip gösterişten uzak duran
NORMAL|Alışılmış duruma uygun
PATIENT|Beklerken sakin kalabilen
PURE|Başka maddeyle karışmamış
RECENT|Yakın zamanda gerçekleşmiş
SIMPLE|Karmaşık olmayan kolay anlaşılır
SUDDEN|Önceden beklenmeden aniden olan
''';

const _hard = '''
AURA|Bir kişiden yayıldığı düşünülen hava
BANE|Yaşamı sürekli zorlaştıran baş belası
BIAS|Yargıyı tek yöne eğen eğilim
BOON|Beklenmedik yarar sağlayan şey
BOUT|Bir hastalığın yoğun biçimde yaşandığı dönem
BULK|Bir şeyin büyük bölümünü oluşturan miktar
CRUX|Bir meselenin çözüm düğümü
GIST|Ayrıntılar çıkarılınca kalan ana düşünce
FEAT|Beceriyle başarılmış dikkat çekici iş
FLAW|Bütünü zayıflatan küçük kusur
FOIL|Bir planın işlemesini engellemek
VICE|Zararlı alışkanlık veya ahlaki kusur
PLOY|Avantaj kazanmak için tasarlanan hamle
RUSE|Gerçeği saklamak için kurulan aldatmaca
GUILE|Aldatarak amaca ulaşma becerisi
WISE|Deneyiminden isabetli yargı çıkarabilen
VAIN|Kendi değerini abartıp gösterişe düşkün
VILE|Ahlaken tiksinti uyandıran
VOID|Hukuki geçerliliği bulunmayan
PACT|Tarafların uyacağı ciddi anlaşma
OATH|Doğruluk veya bağlılık için verilen söz
LORE|Kuşaktan kuşağa aktarılan geleneksel bilgi
MYTH|Kökenleri açıklayan geleneksel anlatı
FABLE|Hayvanlarla ahlaki ders veren kısa anlatı
PARABLE|İnsanların yaşadığı örnek olayla ahlaki ders veren anlatı
ESSAY|Bir konu üzerine kişisel düşünce yazısı
THESIS|Kanıtlanması için ortaya konan temel sav
AXIOM|Başlangıçta doğru kabul edilen önerme
TENET|Bir inanç sisteminin temel ilkelerinden biri
CREED|Benimsenmiş inanç ve ilkeler bütünü
DOGMA|Sorgulanamaz sayılan öğreti
ETHOS|Bir topluluğun davranışına yön veren değerler
LOGIC|Geçerli çıkarımların düzenini inceleyen alan
IRONY|Görünüşle gerçek arasındaki düşündürücü terslik
SATIRE|Toplumsal kusurları alayla eleştiren anlatım
PARODY|Bir eserin biçimini taklitle alaya alma
NUANCE|Anlam veya duygudaki ince fark
SUBTEXT|Açıkça söylenmeyen alttaki anlam
MOTIF|Eserde tekrarlanarak anlam kazanan unsur
THEME|Eserin çevresinde döndüğü ana düşünce
GENRE|Benzer biçimli eserlerin oluşturduğu tür
PROSE|Ölçüye bağlı olmayan yazılı anlatım
VERSE|Şiirin dizelerle kurulan anlatımı
LYRIC|Kişisel duyguları dile getiren kısa şiir
METRIC|Başarıyı sayıyla izlemeye yarayan ölçüt
RATIO|İki miktarın birbirine göre büyüklüğü
SCOPE|Bir çalışmanın kapsadığı sınırlar
SCALE|Boyutlar arasındaki küçültme veya büyütme oranı|medium
RANGE|Alt ve üst sınır arasında kalan aralık|medium
FRAME|Bir düşünceyi yorumlamaya yarayan çerçeve|medium
STANCE|Bir meseleye karşı benimsenen tutum
STATUS|Bir kişinin toplumdaki konumu
LEGACY|Geçmişten geleceğe bırakılan kalıcı etki
ESTATE|Bir kişiye ait taşınmaz mülk bütünü
ASSET|Ekonomik değer taşıyan sahip olunan şey
FISCAL|Kamu gelir ve giderleriyle ilgili
LEVY|Yetkili makamın koyduğu zorunlu ödeme
DEBT|Ödenmesi gereken mali yükümlülük
DUTY|Üstlenilen ahlaki veya resmi yükümlülük
MERIT|Takdir edilmeyi hak ettiren nitelik
VIRTUE|Ahlaken değerli sayılan kişilik niteliği
DIGNITY|İnsanın saygıyı hak eden içsel değeri
CANDID|Düşüncesini saklamadan açıkça söyleyen
TACT|Kimseyi kırmadan davranabilme inceliği
TACIT|Söylenmeden anlaşılıp kabul edilmiş
PRUDENT|Riskleri düşünerek ölçülü davranan
ASTUTE|Durumun gizli yönlerini çabuk kavrayan
SHREWD|Çıkar ve fırsatları keskin biçimde sezebilen
ADEPT|Bir işte yetkinlik kazanmış olan
AGILE|Hızla ve kolayca yön değiştirebilen
NIMBLE|Parmaklarını hızla ve beceriyle hareket ettiren
SUPPLE|Kolay bükülen ve esnekliğini koruyan
TENDER|Dokununca incinebilecek kadar hassas
FRAGILE|Kolayca kırılabilen veya bozulabilen
BRITTLE|Esnemeden kolay kırılan
ROBUST|Zorluklara rağmen güvenilir biçimde işleyen
STURDY|Sağlam yapısıyla kolay yıkılmayan
HARDY|Sert iklimde yaşamını sürdürebilen
STOIC|Acı karşısında duygusunu belli etmeyen
SERENE|İçten gelen dinginliğini koruyan
SOLEMN|Ciddiyet ve ağırbaşlılık taşıyan
GRAVE|Ciddi sonuçları olabilecek ağır nitelikte
DIRE|Acil ve korkunç sonuçlar doğurabilecek
BLEAK|Umut vermeyen soğuk ve kasvetli
GRIM|İç karartıcı derecede ciddi
DREARY|Tekdüze ve sıkıntı verici
SULLEN|Sessizce hoşnutsuzluk gösteren
ACRID|Burun ve boğazı yakan keskin
TART|Damakta keskin ekşilik bırakan
PUNGENT|Keskin kokusu hemen hissedilen
STALE|Tazeliğini yitirip bayatlamış
RANCID|Yağı bozulduğu için kötü kokan
TEPID|Ne sıcak ne soğuk olan
ARDENT|Güçlü ve içten coşkuyla bağlı
ZEALOUS|Bir amaç için aşırı gayretli
FICKLE|Tutumu kolay ve sık değişen
WHIM|Bir anda doğan geçici heves
QUIRK|Kişiye özgü alışılmadık küçük özellik
ANOMALY|Beklenen düzene uymayan durum
PARADOX|Çelişkili görünmesine rağmen düşündüren durum
DILEMMA|İki zor seçenek arasında kalma
ENIGMA|Anlamı kolay çözülemeyen şey
RIDDLE|Yanıtı düşünerek bulunan kısa soru
LATENT|Henüz ortaya çıkmamış ama var olan
DORMANT|Etkinleşmeden bekleyen durumda
OBSCURE|Anlaşılması veya görülmesi güç
OPAQUE|İçinden ışık geçirmeyen
LUCID|Düşüncesi açık ve anlaşılır olan
VIVID|Zihinde güçlü ve canlı iz bırakan
VAGUE|Sınırları veya anlamı net olmayan
BLUNT|Sözünü inceltmeden doğrudan söyleyen
TERSE|Az sözlü, keskin ve bazen soğuk
CONCISE|Gereksiz ayrıntıyı atıp özü koruyan
RAMBLE|Belirli yön izlemeden uzun uzun konuşmak
DIGRESS|Asıl konudan başka yöne sapmak
ELUDE|Yakalanmaktan veya anlaşılmaktan sıyrılmak
EVADE|Sorumluluğu dolaylı yolla atlatmak
AVERT|Kötü bir sonucu önceden engellemek
HINDER|Bir işin ilerlemesini güçleştirmek
IMPEDE|Hareketi engellerle yavaşlatmak
DETER|Caydırıp yapmaktan vazgeçirmek
DAUNT|Zorluğuyla cesaretini kırmak
DREAD|Olacak şeyden büyük korku duymak
YEARN|Uzakta olanı derinden istemek
CRAVE|Bir yiyeceği dayanılmaz biçimde istemek
COVET|Başkasının sahip olduğu şeyi istemek
ENVY|Başkasının üstünlüğüne kıskançlık duymak
LOATHE|Bir şeyden güçlü biçimde tiksinmek
SCORN|Değersiz görerek küçümsemek
REBUKE|Bir davranışı sert sözlerle kınamak
TAUNT|Kızdırmak için alaycı söz söylemek
MOCK|Taklit ederek alaya almak
REJOICE|İyi bir olaydan içten mutluluk duymak
RELISH|Bir deneyimin tadını çıkararak hoşlanmak
CHERISH|Değer verdiğini özenle korumak
REVERE|Derin saygıyla yüceltmek
ESTEEM|Birini değerli görüp saygı duymak
EXTOL|Üstün nitelikleri coşkuyla övmek
HAIL|Bir gelişmeyi memnuniyetle karşılamak
HEED|Uyarıyı dikkate alıp davranmak
HONE|Beceriyi çalışarak keskinleştirmek
WIELD|Bir araç veya yetkiyi etkili kullanmak
PROBE|Gizli ayrıntıyı dikkatle araştırmak
DELVE|Bir konunun derinine inmek
SIFT|Gereksizi ayırmak için dikkatle taramak
GAUGE|Bir şeyin derecesini ölçüp kestirmek
INFER|Verilenlerden söylenmeyen sonucu çıkarmak
DEDUCE|Genel bilgiden belirli sonuca varmak
DISCERN|İnce farkı ayırt ederek görmek
DEEM|Bir şeyi belli nitelikte saymak
ASSERT|Bir görüşü kararlılıkla öne sürmek
AFFIRM|Bir gerçeği açıkça doğrulamak
ALLEGE|Henüz kanıtlanmamış iddiayı ileri sürmek
IMPLY|Açıkça söylemeden düşündürmek
DENOTE|Bir işaretle belirli anlamı göstermek
ALLUDE|Doğrudan anlatmadan bir şeye değinmek
EVOKE|Bir anıyı veya duyguyu uyandırmak
ENTAIL|Bir sonucu kaçınılmaz olarak gerektirmek
CITE|Bir kaynağı kanıta dayanak olarak göstermek
QUOTE|Birinin sözlerini değiştirmeden aktarmak
RECAST|Aynı şeyi farklı biçimde ifade etmek
REVISE|Yeniden inceleyip düzeltmek
AMEND|Yasa metnini kısmen değiştirerek düzeltmek
RECTIFY|Yanlış durumu doğru hale getirmek
ATONE|Yaptığı yanlışın karşılığını telafi etmek
REDEEM|Bir kusurun etkisini iyi yönle gidermek
WAIVE|Bir hakkı kullanmaktan gönüllü vazgeçmek
CEDE|Toprak veya denetimi resmen başkasına bırakmak
YIELD|Baskı karşısında direnmekten vazgeçmek
FORGO|Bir yarardan isteyerek vazgeçmek
REVOKE|Verilmiş izni resmen geri almak
RESCIND|Önceki kararı geçersiz kılmak
REPEAL|Yürürlükteki yasayı kaldırmak
ANNUL|Bir işlemi hukuken geçersiz saymak
NULLIFY|Etkisini tamamen ortadan kaldırmak
NEGATE|Bir savın doğru olmadığını göstermek
REFUTE|İddiayı kanıtla çürütmek
REBUT|Bir eleştiriye karşı gerekçeli yanıt vermek
DISPUTE|Doğruluğuna itiraz edip tartışmak
DISSENT|Çoğunluğun görüşüne katılmadığını bildirmek
ASSENT|Bir öneriyi kabul ettiğini belirtmek
CONCUR|Bağımsız değerlendirmeyle aynı yargıya varmak
DEFER|Kararı veya işi sonraya bırakmak
ADJOURN|Toplantıyı daha sonra sürmek üzere durdurmak
DELAY|Beklenen zamanı daha ileriye atmak
LINGER|Gitme zamanı geçtiği halde kalmak
LOITER|Amaçsızca bir yerde oyalanmak
AMBLE|Yavaş ve rahat adımlarla yürümek
SAUNTER|Acele etmeden keyifle dolaşmak
STRIDE|Uzun ve kararlı adımlarla yürümek
TRUDGE|Yorgunlukla ağır adımlarla ilerlemek
STAGGER|Dengesini kaybederek sendelemek
LURCH|Aniden ve dengesizce öne atılmak
SWAY|Bir yandan ötekine sallanmak
VEER|İzlenen yönden aniden sapmak
DART|Birden hızla bir yöne fırlamak
FLIT|Bir noktadan ötekine hızla geçmek
GLIDE|Yüzeyde yumuşakça kayarak ilerlemek
SOAR|Yükseğe doğru hızla yükselmek
PLUNGE|Birden derine doğru dalmak
DIVE|Baş aşağı suya dalmak
DRIFT|Akıntı veya rüzgarla sürüklenmek
FLOAT|Batmadan yüzeyde kalmak
SUBSIDE|Yoğunluğu zamanla azalıp yatışmak
ABATE|Fırtınanın veya ağrının şiddetinin azalması
WANE|Gücünü yavaş yavaş yitirmek
FADE|Renk veya canlılığını yavaşça kaybetmek
DWINDLE|Giderek daha küçük hale gelmek
WITHER|Canlılığını yitirerek kuruyup büzülmek
WILT|Diriliğini yitirip aşağı sarkmak
SHRIVEL|Kuruyarak küçülüp kırışmak
DECAY|Zamanla çürüyüp bozulmak
ERODE|Aşındırarak yavaşça ortadan kaldırmak
CORRODE|Kimyasal etkiyle aşınıp bozulmak
TARNISH|Parlaklığı veya itibarı zedelemek
TAINT|Saflığına zarar veren bulaşma oluşturmak
BLEMISH|Görünümü bozan küçük leke
SCAR|Yara iyileştikten sonra kalan iz
SCUFF|Sürtünmenin bıraktığı yüzeysel iz
DENT|Sert yüzeyde içe doğru oluşan çukur
CHIP|Sert bir şeyden kopmuş küçük parça
SHARD|Kırılan cam veya seramiğin keskin parçası
SLIVER|İnce uzun küçük parça
REMNANT|Bir bütünden geriye kalmış parça
RESIDUE|İşlem bittikten sonra kalan madde
TRACE|Bir varlığın bıraktığı çok küçük iz
VESTIGE|Yok olmuş şeyden kalan son belirti
TOKEN|Daha büyük bir şeyi temsil eden işaret
EMBLEM|Bir topluluğu temsil eden simge
BADGE|Aidiyeti veya başarıyı gösteren küçük işaret
CREST|Bir şeklin veya dalganın en üstü
PEAK|Grafikte gözlenen en yüksek değer|medium
APEX|Konik bir şeklin sivri uç noktası
ZENITH|Başarının eriştiği en yüksek aşama
NADIR|Bir sürecin en düşük noktası
DEPTH|Düşüncenin yüzeyin ötesine inme düzeyi
ABYSS|Dibi görünmeyen büyük derinlik
CHASM|İki yamaç arasındaki derin açıklık
GULF|İki tarafı ayıran büyük anlaşmazlık
RIFT|Yakın kişiler arasında açılan ayrılık
BREACH|Bir kuralın veya anlaşmanın ihlali
RUPTURE|Dokunun veya zarın aniden yırtılması
SEVER|Bir bağlantıyı tamamen kesmek
SPLIT|Bir bütünü keskin biçimde ayırmak
CLEAVE|Bir kütleyi darbeyle yarıp ayırmak
ACRE|Arazinin büyüklüğünü belirten ölçü birimi
ARID|Yağışı çok az olan
BARD|Toplumun öykülerini şiirle aktaran kişi
BARK|Ağacın dış koruyucu katmanı
BEAM|Bir yükü taşıyan yatay uzun parça
BRIM|Bir kabın üst açık kenarı
BRINK|Tehlikeli sonuca çok yakın eşik
CURB|Taşkın davranışı sınırlamak
CURT|Cevabı kısa tutarken kabalaşan
DEFT|Eli çabuk ve becerikli
DUSK|Gün batımıyla karanlık arasındaki zaman
ECHO|Sesin yüzeyden dönerek yeniden duyulması
FATE|Denetim dışında gelişen yaşam yolu
FEND|Yardım almadan kendi ihtiyaçlarını karşılamak
FLEE|Tehlikeden hızla uzaklaşmak
GAIT|Birinin adımlarındaki yürüyüş biçimi
GASP|Şaşkınlıkla aniden soluk almak
GLEE|Coşkulu ve açıkça görülen sevinç
GLOW|Yoğun olmayan sürekli ışık yaymak
GNAW|Küçük ısırıklarla kemirerek aşındırmak
HALO|Bir şeyin çevresindeki ışıklı halka
HOAX|İnsanları yanıltmak için uydurulmuş olay
IDLE|Çalışmadan veya kullanılmadan duran
LULL|Yoğun faaliyet arasındaki kısa durgunluk
LURE|Birini cezbederek belirli yere çekmek
MUSE|Bir düşünce üzerinde dalgınca durmak
MUTE|Ses çıkarmayan veya sesi kapatılmış
NEST|İç içe yerleştirerek düzenlemek|medium
OMEN|Geleceği haber verdiğine inanılan belirti
POISE|Baskı altında korunan sakin özgüven
RAPT|Çevresini unutacak kadar dikkat kesilmiş
ROVE|Belirli hedef olmadan geniş alanda dolaşmak
SAGE|Deneyimle derin anlayış edinmiş kişi
SEEP|Küçük aralıklardan yavaşça sızmak
SHUN|Bir kişiyle temastan bilinçli kaçınmak
SNAG|İlerlemeyi durduran beklenmedik küçük engel
SOOT|Tam yanmama sonucu biriken siyah toz
SPUR|Bir eyleme yönelten güçlü dürtü
STEM|Bir durumun belli bir kaynaktan doğması|medium
STIR|Duyguyu harekete geçirip uyandırmak
SWAP|İki şeyin yerini karşılıklı değiştirmek
SWIRL|Dönerek kıvrımlı biçimde hareket etmek
SWOON|Yoğun duyguyla kendinden geçmek
TOLL|Bir olayın insanlarda bıraktığı ağır bedel
TRIM|Fazla kısmı keserek düzenlemek
VAST|Sınırları çok geniş olan
VEIL|Gerçeği görünmez kılan örtü
VENT|Biriktirdiği duyguyu dışa vurmak
WAFT|Hafifçe havada taşınarak ilerlemek
WEAN|Bir alışkanlıktan yavaşça uzaklaştırmak
WHEEZE|Nefes alırken ıslıklı ses çıkarmak
WINCE|Acı veya rahatsızlıkla yüzünü buruşturmak
WILY|Kurnaz yollarla istediğine ulaşan
WARY|Tehlike olasılığına karşı tetikte
ZEAL|Bir amaç için gösterilen yoğun gayret
''';
