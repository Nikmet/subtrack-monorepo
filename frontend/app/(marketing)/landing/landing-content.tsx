import Image from "next/image";
import Link from "next/link";
import {
  ArrowRight,
  BellDot,
  CalendarClock,
  Check,
  ChevronRight,
  CreditCard,
  Download,
  LayoutDashboard,
  RefreshCw,
  Smartphone,
  WalletCards,
} from "lucide-react";

import styles from "./landing.module.css";

const apkHref = "/api/v1/downloads/android";

const trustFacts = [
  {
    title: "Контроль подписок",
    body: "Все регулярные платежи собраны в одном месте и не теряются между банками и сервисами.",
  },
  {
    title: "Единая аналитика",
    body: "Расходы видно по категориям, суммам и платёжным картам без ручного учёта.",
  },
  {
    title: "Web + Android",
    body: "Один продукт для ежедневного контроля на десктопе и быстрых действий со смартфона.",
  },
  {
    title: "Спокойствие в деталях",
    body: "Календарь списаний и актуальные данные по картам снижают риск забытых автоплатежей.",
  },
];

const benefits = [
  {
    icon: LayoutDashboard,
    title: "Порядок вместо шума",
    body: "SubTrack превращает хаотичные recurring-платежи в аккуратную систему, где важное видно сразу.",
    detail: "Домашний экран с итогами, активными подписками и быстрыми действиями.",
  },
  {
    icon: CalendarClock,
    title: "Ясность по будущим списаниям",
    body: "Календарь показывает, когда и за что спишутся деньги, без ручных напоминаний и заметок.",
    detail: "Следующие платежи, ближайшие даты и структура расходов в одной логике.",
  },
  {
    icon: WalletCards,
    title: "Контроль карт и автоплатежей",
    body: "Для каждой подписки видно карту оплаты, а редактирование происходит там, где вы уже работаете.",
    detail: "Изменение карты, даты списания и удаление подписки без лишних переходов.",
  },
];

const featurePanels = [
  {
    id: "analytics",
    eyebrow: "Аналитика расходов",
    title: "Сразу видно, куда уходят деньги каждый месяц.",
    body:
      "Главный экран показывает общую сумму подписок, распределение по категориям и структуру расходов по картам. Это не отчёт ради отчёта, а спокойная ежедневная ясность.",
    points: ["Сумма месяца без ручного подсчёта", "Категории и карты в одной картине", "Подходит для личных и рабочих сервисов"],
    visual: "analytics" as const,
  },
  {
    id: "calendar",
    eyebrow: "Календарь списаний",
    title: "Предстоящие платежи больше не становятся сюрпризом.",
    body:
      "SubTrack показывает, что спишется в ближайшие дни, какие сервисы активны и как распределяются платежи по времени. Это снижает шум и упрощает планирование.",
    points: ["Наглядная временная линия", "Быстрый просмотр ближайших дат", "Прозрачный ритм всех подписок"],
    visual: "calendar" as const,
  },
  {
    id: "management",
    eyebrow: "Управление подписками",
    title: "Редактирование и удаление встроены в основной рабочий поток.",
    body:
      "Подписки можно обновлять прямо с домашнего экрана: изменить дату следующего платежа, выбрать другую карту или удалить сервис, если он больше не нужен.",
    points: ["Действия на уровне карточки", "Контекстное редактирование без лишних экранов", "Меньше трения в реальных сценариях"],
    visual: "management" as const,
  },
  {
    id: "payments",
    eyebrow: "Карты и автоплатежи",
    title: "Удерживайте контроль не только над сервисами, но и над способом оплаты.",
    body:
      "Карточки оплаты, текущая карта подписки и автосписания остаются прозрачными. Это особенно важно, когда сервисов становится много, а расходы начинают расползаться.",
    points: ["Понятная связка сервисов и карт", "Отображение автоплатежей без перегруза", "Одна система для web и Android"],
    visual: "payments" as const,
  },
];

const steps = [
  {
    index: "01",
    title: "Добавьте сервисы",
    body: "Выберите подписку из каталога или создайте свою, укажите дату платежа и карту оплаты.",
  },
  {
    index: "02",
    title: "Смотрите реальную картину",
    body: "Домашний экран, аналитика и календарь мгновенно собирают recurring-платежи в понятную систему.",
  },
  {
    index: "03",
    title: "Корректируйте по ходу",
    body: "Обновляйте дату, карту или саму подписку тогда, когда это действительно нужно, без лишних действий.",
  },
];

const faqs = [
  {
    question: "Что можно отслеживать в SubTrack?",
    answer:
      "Любые регулярные сервисы: стриминги, VPN, хранилища, рабочие SaaS-инструменты, домены и другие recurring-платежи, которые важно держать под контролем.",
  },
  {
    question: "Есть ли мобильное приложение?",
    answer:
      "Да. У SubTrack есть Android-приложение, которое скачивается напрямую по APK. Кнопка на лендинге запускает загрузку без дополнительного store-шага.",
  },
  {
    question: "Можно ли менять карту и дату следующего платежа?",
    answer:
      "Да. С домашнего экрана можно редактировать подписку, выбрать другую карту и обновить дату следующего списания без ухода в длинный сценарий настроек.",
  },
  {
    question: "Для кого подходит SubTrack?",
    answer:
      "Для пользователей, которые хотят видеть подписки спокойно и прозрачно: личные сервисы, цифровые рабочие инструменты и любые регулярные платежи, которые накапливаются со временем.",
  },
];

function SectionHeading({
  eyebrow,
  title,
  description,
  center = false,
}: {
  eyebrow: string;
  title: string;
  description?: string;
  center?: boolean;
}) {
  return (
    <div className={`${styles.sectionHeading} ${center ? styles.sectionHeadingCenter : ""}`}>
      <span className={styles.sectionEyebrow}>{eyebrow}</span>
      <h2>{title}</h2>
      {description ? <p>{description}</p> : null}
    </div>
  );
}

function ProductVisual({ type }: { type: (typeof featurePanels)[number]["visual"] }) {
  if (type === "analytics") {
    return (
      <div className={styles.visualBoard}>
        <div className={styles.visualHeader}>
          <span>Аналитика</span>
          <span className={styles.visualPill}>1 108 ₽ / мес</span>
        </div>
        <div className={styles.metricBars}>
          {[
            ["Стриминг", "449 ₽", "41%", styles.barMint],
            ["Прочее", "360 ₽", "32%", styles.barBlue],
            ["Финансы", "299 ₽", "27%", styles.barGold],
          ].map(([label, amount, share, className]) => (
            <div key={label} className={styles.metricBarRow}>
              <div className={styles.metricTop}>
                <strong>{label}</strong>
                <span>{amount}</span>
              </div>
              <div className={styles.metricTrack}>
                <span className={`${styles.metricFill} ${className}`} style={{ width: share }} />
              </div>
              <small>{share} от общих расходов</small>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (type === "calendar") {
    return (
      <div className={styles.visualBoard}>
        <div className={styles.visualHeader}>
          <span>Календарь списаний</span>
          <span className={styles.visualPill}>Апрель</span>
        </div>
        <div className={styles.timelineList}>
          {[
            ["09 апр.", "Яндекс Плюс", "449 ₽"],
            ["14 апр.", "T-Банк PRO", "299 ₽"],
            ["26 апр.", "Liberty VPN", "349 ₽"],
          ].map(([date, title, amount]) => (
            <div key={title} className={styles.timelineItem}>
              <div className={styles.timelineDate}>{date}</div>
              <div className={styles.timelineCopy}>
                <strong>{title}</strong>
                <span>Следующее автосписание</span>
              </div>
              <div className={styles.timelineAmount}>{amount}</div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (type === "management") {
    return (
      <div className={styles.visualBoard}>
        <div className={styles.visualHeader}>
          <span>Мои подписки</span>
          <span className={styles.visualPill}>4 активные</span>
        </div>
        <div className={styles.subscriptionMiniList}>
          {[
            ["Liberty VPN", "26 мар.", "349 ₽ / мес"],
            ["Яндекс Плюс", "09 апр.", "449 ₽ / мес"],
          ].map(([title, date, amount]) => (
            <div key={title} className={styles.subscriptionMiniCard}>
              <div className={styles.subscriptionMiniTop}>
                <div>
                  <strong>{title}</strong>
                  <span>Следующий платёж {date}</span>
                </div>
                <button type="button" className={styles.dotsButton} aria-label={`Действия для ${title}`}>
                  <span />
                  <span />
                  <span />
                </button>
              </div>
              <div className={styles.subscriptionMiniBottom}>
                <b>{amount}</b>
                <span className={styles.autopayBadge}>Автосписание</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className={styles.visualBoard}>
      <div className={styles.visualHeader}>
        <span>Карты оплаты</span>
        <span className={styles.visualPill}>1 основная</span>
      </div>
      <div className={styles.paymentStack}>
        <div className={styles.paymentCardPrimary}>
          <div className={styles.paymentCardTop}>
            <strong>T-Банк</strong>
            <CreditCard size={18} />
          </div>
          <div className={styles.paymentCardNumber}>2202 •••• •••• •••• 222</div>
          <div className={styles.paymentCardFooter}>
            <span>4 подписки</span>
            <span>100% monthly total</span>
          </div>
        </div>
        <div className={styles.paymentRows}>
          {[
            ["Яндекс Плюс", "T-Банк", "2202 •••• 222"],
            ["Liberty VPN", "T-Банк", "2202 •••• 222"],
          ].map(([service, bank, card]) => (
            <div key={service} className={styles.paymentRow}>
              <div>
                <strong>{service}</strong>
                <span>{bank}</span>
              </div>
              <small>{card}</small>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function FeaturePanel({
  eyebrow,
  title,
  body,
  points,
  visual,
  reverse = false,
}: {
  eyebrow: string;
  title: string;
  body: string;
  points: string[];
  visual: (typeof featurePanels)[number]["visual"];
  reverse?: boolean;
}) {
  return (
    <article className={`${styles.featurePanel} ${reverse ? styles.featurePanelReverse : ""}`}>
      <div className={styles.featureCopy}>
        <span className={styles.panelEyebrow}>{eyebrow}</span>
        <h3>{title}</h3>
        <p>{body}</p>
        <ul className={styles.panelPoints}>
          {points.map((point) => (
            <li key={point}>
              <Check size={16} />
              <span>{point}</span>
            </li>
          ))}
        </ul>
      </div>
      <div className={styles.featureVisual}>
        <ProductVisual type={visual} />
      </div>
    </article>
  );
}

function FaqItem({ question, answer }: { question: string; answer: string }) {
  return (
    <details className={styles.faqItem}>
      <summary>
        <span>{question}</span>
        <ChevronRight size={18} />
      </summary>
      <p>{answer}</p>
    </details>
  );
}

export function LandingContent() {
  return (
    <main className={styles.page}>
      <div className={styles.backgroundGrid} aria-hidden />
      <section className={styles.heroSection}>
        <header className={styles.header}>
          <Link href="/landing" className={styles.brand}>
            <Image src="/logo.svg" alt="SubTrack" width={34} height={34} priority />
            <span>SubTrack</span>
          </Link>
          <nav className={styles.nav}>
            <a href="#benefits">Преимущества</a>
            <a href="#features">Возможности</a>
            <a href="#showcase">Интерфейс</a>
            <a href="#faq">FAQ</a>
          </nav>
          <a href={apkHref} data-top-loader="ignore" className={styles.headerCta}>
            Скачать APK
          </a>
        </header>

        <div className={styles.heroLayout}>
          <div className={styles.heroCopy}>
            <span className={styles.heroEyebrow}>Financial clarity for subscriptions</span>
            <h1>Все подписки под контролем. Все расходы видны сразу.</h1>
            <p>
              SubTrack помогает спокойно управлять регулярными платежами: видеть общую картину,
              отслеживать ближайшие списания, контролировать карты оплаты и редактировать подписки
              без лишнего шума.
            </p>
            <div className={styles.heroActions}>
              <a href={apkHref} data-top-loader="ignore" className={styles.primaryButton}>
                <Download size={18} />
                Скачать для Android
              </a>
              <a href="#showcase" className={styles.secondaryButton}>
                Посмотреть интерфейс
                <ArrowRight size={18} />
              </a>
            </div>
            <div className={styles.heroSignals}>
              <div className={styles.signalCard}>
                <span className={styles.signalLabel}>Ежемесячные расходы</span>
                <strong>1 108 ₽ / мес</strong>
              </div>
              <div className={styles.signalCard}>
                <span className={styles.signalLabel}>Активные подписки</span>
                <strong>4 под контролем</strong>
              </div>
              <div className={styles.signalCard}>
                <span className={styles.signalLabel}>Платформы</span>
                <strong>Web + Android</strong>
              </div>
            </div>
          </div>

          <div className={styles.heroStage}>
            <div className={styles.stageShell}>
              <div className={styles.stageTopBar}>
                <span className={styles.stageDot} />
                <span className={styles.stageDot} />
                <span className={styles.stageDot} />
              </div>
              <div className={styles.stageFrame}>
                <Image
                  src="/landing/dashboard-shot.png"
                  alt="Интерфейс SubTrack с домашней аналитикой"
                  width={1600}
                  height={1100}
                  className={styles.stageImage}
                  priority
                />
              </div>
            </div>
            <div className={styles.overlayStat}>
              <div className={styles.overlayStatTop}>
                <BellDot size={16} />
                <span>Ближайшее списание</span>
              </div>
              <strong>Яндекс Плюс • 09 апр.</strong>
              <small>449 ₽ · T-Банк · автосписание активно</small>
            </div>
            <div className={styles.overlayMobile}>
              <div className={styles.mobileChrome}>
                <Image
                  src="/landing/mobile-shot.png"
                  alt="Мобильный интерфейс SubTrack"
                  width={900}
                  height={1400}
                  className={styles.mobilePreview}
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className={styles.trustSection}>
        <div className={styles.trustStrip}>
          {trustFacts.map((fact) => (
            <article key={fact.title} className={styles.trustCard}>
              <strong>{fact.title}</strong>
              <p>{fact.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className={styles.section} id="benefits">
        <SectionHeading
          eyebrow="Преимущества"
          title="SubTrack ощущается как спокойный центр управления, а не как ещё один список платежей."
          description="Мы берём визуальный язык продукта и доводим его до SaaS-уровня: чисто, структурно, без лишнего маркетингового шума."
        />
        <div className={styles.benefitGrid}>
          {benefits.map(({ icon: Icon, title, body, detail }) => (
            <article key={title} className={styles.benefitCard}>
              <div className={styles.benefitIcon}>
                <Icon size={20} />
              </div>
              <h3>{title}</h3>
              <p>{body}</p>
              <small>{detail}</small>
            </article>
          ))}
        </div>
      </section>

      <section className={styles.section} id="features">
        <SectionHeading
          eyebrow="Product showcase"
          title="Реальный интерфейс продукта становится главным аргументом."
          description="Каждый блок ниже показывает не абстрактную выгоду, а конкретный сценарий использования SubTrack."
        />
        <div className={styles.featureStack}>
          {featurePanels.map((panel, index) => (
            <FeaturePanel key={panel.id} {...panel} reverse={index % 2 === 1} />
          ))}
        </div>
      </section>

      <section className={styles.section}>
        <SectionHeading
          eyebrow="How it works"
          title="Три шага к прозрачным recurring-платежам."
          description="Сценарий остаётся простым даже тогда, когда количество подписок уже перестало быть маленьким."
          center
        />
        <div className={styles.stepsGrid}>
          {steps.map((step) => (
            <article key={step.index} className={styles.stepCard}>
              <span className={styles.stepIndex}>{step.index}</span>
              <h3>{step.title}</h3>
              <p>{step.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className={styles.section} id="showcase">
        <SectionHeading
          eyebrow="Interface showcase"
          title="Настоящий продукт внутри, а не обещание на будущее."
          description="Лендинг показывает интерфейс SubTrack как зрелую систему: dashboard, mobile companion и ключевые продуктовые паттерны."
        />
        <div className={styles.showcaseLayout}>
          <article className={styles.showcaseMain}>
            <div className={styles.showcaseHeader}>
              <div>
                <span>Web dashboard</span>
                <strong>Домашняя аналитика и управление подписками</strong>
              </div>
              <span className={styles.showcaseBadge}>Desktop</span>
            </div>
            <div className={styles.showcaseScreen}>
              <Image src="/landing/dashboard-shot.png" alt="Dashboard preview" width={1600} height={1100} className={styles.showcaseImage} />
            </div>
          </article>
          <div className={styles.showcaseSide}>
            <article className={styles.showcaseSmallCard}>
              <div className={styles.showcaseSmallHeader}>
                <Smartphone size={18} />
                <span>Android companion</span>
              </div>
              <div className={styles.showcasePhone}>
                <Image src="/landing/mobile-shot.png" alt="Mobile preview" width={900} height={1400} className={styles.showcasePhoneImage} />
              </div>
            </article>
            <article className={styles.showcaseNote}>
              <strong>Один визуальный язык</strong>
              <p>
                Светлый холодный фон, тёмно-синие product surfaces, мягкие бордеры и мятный акцент
                создают ощущение контроля и ясности в обеих версиях продукта.
              </p>
            </article>
          </div>
        </div>
      </section>

      <section className={styles.section} id="faq">
        <SectionHeading
          eyebrow="FAQ"
          title="Коротко о том, что важно перед стартом."
          description="Без маркетингового тумана: только практические ответы о том, как работает продукт."
        />
        <div className={styles.faqList}>
          {faqs.map((faq) => (
            <FaqItem key={faq.question} {...faq} />
          ))}
        </div>
      </section>

      <section className={styles.section}>
        <div className={styles.finalCta}>
          <div className={styles.finalCopy}>
            <span className={styles.sectionEyebrow}>Start with clarity</span>
            <h2>Подключите SubTrack и держите подписки в аккуратной, прозрачной системе.</h2>
            <p>
              Установите Android-приложение и получите ту же продуктовую логику контроля, которую
              вы видите на лендинге: аналитика, календарь, карты и спокойствие в ежедневных расходах.
            </p>
          </div>
          <div className={styles.finalActions}>
            <a href={apkHref} data-top-loader="ignore" className={styles.primaryButton}>
              <Download size={18} />
              Скачать APK
            </a>
            <a href="#features" className={styles.finalLink}>
              Изучить возможности
              <RefreshCw size={16} />
            </a>
          </div>
        </div>
      </section>

      <footer className={styles.footer}>
        <Link href="/landing" className={styles.brand}>
          <Image src="/logo.svg" alt="SubTrack" width={28} height={28} />
          <span>SubTrack</span>
        </Link>
        <div className={styles.footerMeta}>
          <a href="#benefits">Преимущества</a>
          <a href="#features">Возможности</a>
          <a href="#showcase">Интерфейс</a>
          <a href={apkHref} data-top-loader="ignore">
            Скачать APK
          </a>
        </div>
      </footer>
    </main>
  );
}
