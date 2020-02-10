<%--
  Created by IntelliJ IDEA.
  User: jorge.carrillo
  Date: 2/5/2020
  Time: 1:05 PM
  To change this template use File | Settings | File Templates.
--%>
<%-- <%@ page contentType="text/html;charset=UTF-8" language="java" %>  plus besoin de la mettre, on a fait le nécessaire
     sur WEB.XML--%>
<html>
<head>
    <title>Title</title>
</head>
<body>

<%--
************************************************************************************************************************
                              Le cookie : le navigateur vous ouvre ses portes
************************************************************************************************************************

Nous avons déjà bien entamé la découverte du cookie malgré nous, lorsque nous avons étudié le fonctionnement des
sessions, mais nous allons tout de même prendre la peine de rappeler les concepts qui se cachent sous cette technologie.
Nous allons ensuite mettre en pratique la théorie dans un exemple concret, et terminer sur une discussion autour de
leur sécurité.

************************************************************************************************************************
                                         Le principe du cookie
************************************************************************************************************************

Le principe général est simple : il s'agit d'un petit fichier placé directement dans le navigateur du client. Il lui
est envoyé par le serveur à travers les en-têtes de la réponse HTTP, et ne contient que du texte. Il est propre à un
site ou à une partie d'un site en particulier, et sera renvoyé par le navigateur dans toutes les requêtes HTTP adressées
à ce site ou à cette partie du site

**********************
      Côté HTTP
**********************

Pour commencer, le cookie est une notion qui est liée au protocole HTTP, et qui est définie par la RFC 6265 depuis
avril 2011. Cette nouvelle version de la norme rend caduque la version 2965, qui elle-même remplaçait la version 2109.
Si vous avez du temps à perdre, vous pouvez chercher les modifications apportées au fil des évolutions, c'est un
excellent exercice d'analyse de RFC, ces documents massifs qui font office de référence absolue dans bon nombre de domaines !

Ça, c'était pour la théorie. Dans la pratique, dans le chapitre portant sur les sessions nous avons déjà analysé des
échanges HTTP impliquant des transferts de cookies du serveur vers le navigateur et inversement, et avons découvert que :

    * un cookie a obligatoirement un nom et une valeur associée ;

    * un cookie peut se voir attribuer certaines options, comme une date d'expiration ;

    * le serveur demande la mise en place ou le remplacement d'un cookie par le paramètre Set-Cookie dans l'en-tête
      de la réponse HTTP qu'il envoie au client ;

    * le client transmet au serveur un cookie par le paramètre Cookie dans l'en-tête de la requête HTTP qu'il envoie
      au serveur.

C'est tout ce qui se passe dans les coulisses du protocole HTTP, il s'agit uniquement d'un paramètre dans la requête
ou dans la réponse.

**********************
    Côté Java EE
**********************

La plate-forme Java EE permet de manipuler un cookie à travers l'objet Java Cookie. Sa documentation claire et concise
nous informe notamment que :

    * un cookie doit obligatoirement avoir un nom et une valeur ;

    * il est possible d'attribuer des options à un cookie, telles qu'une date d'expiration ou un numéro de version.
      Toutefois, elle nous précise ici que certains navigateurs présentent des bugs dans leur gestion de ces options,
      et qu'il est préférable d'en limiter l'usage autant que faire se peut afin de rendre notre application aussi
      multiplateforme que possible ;

    * la méthode addCookie() de l'objet HttpServletResponse est utilisée pour ajouter un cookie à la réponse qui sera
      envoyée au client ;

    * la méthode getCookies() de l'objet HttpServletRequest est utilisée pour récupérer la liste des cookies envoyés
      par le client ;

    * par défaut, les objets ainsi créés respectent la toute première norme décrivant les cookies HTTP, une norme
      encore plus ancienne que la 2109 dont je vous ai parlé dans le paragraphe précédent, afin d'assurer la meilleure
      interopérabilité possible. La documentation de la méthode setVersion() nous précise même que la version 2109 est
      considérée comme "récente et expérimentale". Bref, la documentation commence sérieusement à dater... Peu importe,
      tout ce dont nous avons besoin pour le moment était déjà décrit dans le tout premier document, pas de soucis à
      se faire ! :)

Voilà tout ce qu'il vous est nécessaire de savoir pour attaquer. Bien évidemment, n'hésitez pas à parcourir plus en
profondeur la Javadoc de l'objet Cookie pour en connaître davantage !

Avant de passer à la pratique, comprenez bien que cookies et sessions sont deux concepts totalement distincts !
Même s'il est vrai que l'établissement d'une session en Java EE peut s'appuyer sur un cookie, il ne faut pas confondre
les deux notions : la session est un espace mémoire alloué sur le serveur dans lequel vous pouvez placer n'importe quel
type d'objets, alors que le cookie est un espace mémoire alloué dans le navigateur du client dans lequel vous ne pouvez
placer que du texte.

************************************************************************************************************************
                                       Souvenez-vous de vos clients !
************************************************************************************************************************

Pour illustrer la mise en place d'un cookie chez l'utilisateur, nous allons donner à notre formulaire de connexion...
une mémoire ! Plus précisément, nous allons donner le choix à l'utilisateur d'enregistrer ou non la date de sa dernière
connexion, via une case à cocher dans notre formulaire. S'il fait ce choix, alors nous allons stocker la date et l'heure
de sa connexion dans un cookie et le placer dans son navigateur. Ainsi, à son retour après déconnexion, nous serons en
mesure de lui afficher depuis combien de temps il ne s'est pas connecté.

Ce système ne fera donc intervenir qu'un seul cookie, chargé de sauvegarder la date de connexion.

Alors bien évidemment, c'est une simple fonctionnalité que je vous fais mettre en place à titre d'application pratique :
elle est aisément faillible, par exemple si l'utilisateur supprime les cookies de son navigateur, les bloque, ou encore
s'il se connecte depuis un autre poste ou un autre navigateur. Mais peu importe, le principal est que vous travailliez
la manipulation de cookies, et au passage cela vous donnera une occasion :

    * de travailler à nouveau la manipulation des dates avec la bibliothèque JodaTime ;

    * de découvrir comment traiter une case à cocher, c'est-à-dire un champ de formulaire HTML de type
      <input type="checkbox"/>.

D'une pierre... trois coups ! ;)

**************************
  Reprise de la servlet
**************************

Le plus gros de notre travail va se concentrer sur la servlet de connexion. C'est ici que nous allons devoir manipuler
notre unique cookie, et effectuer différentes vérifications. En reprenant calmement notre système, nous pouvons
identifier les deux besoins suivants :

   1) à l'affichage du formulaire de connexion par un visiteur, il nous faut vérifier si le cookie enregistrant la date
      de la précédente connexion a été envoyé dans la requête HTTP par le navigateur du client. Si oui, alors cela
      signifie que le visiteur s'est déjà connecté par le passé avec ce navigateur, et que nous pouvons donc lui afficher
      depuis combien de temps il ne s'est pas connecté. Si non, alors il ne s'est jamais connecté et nous lui affichons
      simplement le formulaire ;

   2) à la connexion d'un visiteur, il nous faut vérifier s'il a coché la case dans le formulaire, et si oui il nous
      faut récupérer la date courante, l'enregistrer dans un cookie et l'envoyer au navigateur du client à travers la
      réponse HTTP.

*******************************
  À l'affichage du formulaire
*******************************

Lors de la réception d'une demande d'accès à la page de connexion, la méthode doGet() de notre servlet va devoir :

    * vérifier si un cookie a été envoyé par le navigateur dans les en-têtes de la requête ;

    * si oui, alors elle doit calculer la différence entre la date courante et la date présente dans le cookie, et la
      transmettre à la JSP pour affichage.

Voici pour commencer la reprise de la méthode doGet(), accompagnée des nouvelles constantes et méthodes nécessaires à
son bon fonctionnement. Je n'ai volontairement pas inclus le code existant de la méthode doPost(), afin de ne pas
compliquer la lecture. Lorsque vous reporterez ces modifications sur votre servlet de connexion, ne faites surtout pas
un bête copier-coller du code suivant ! Prenez garde à modifier correctement le code existant, et à ne pas supprimer la
méthode doPost() de votre servlet (que j'ai ici remplacée par "...") :

************************************************************************************************************************

De plus amples explications :

  * j'ai choisi de nommer le cookie stocké chez le client derniereConnexion ;

  * j'ai mis en place une méthode nommée getCookieValue(), dédiée à la recherche d'un cookie donné dans une requête HTTP :

        . à la ligne 56, elle récupère tous les cookies présents dans la requête grâce à la méthode request.getCookies(),
          que je vous ai présentée un peu plus tôt ;

        . à la ligne 57, elle vérifie si des cookies existent, c'est-à-dire si request.getCookies() n'a pas retourné null ;

        . à la ligne 58, elle parcourt le tableau de cookies récupéré ;

        . à la ligne 59, elle vérifie si un des éventuels cookies présents dans le tableau a le même nom que le paramètre
          nom passé en argument, récupéré par un appel à cookie.getName() ;

        . à la ligne 60, si un tel cookie est trouvé, elle retourne sa valeur via un appel à cookie.getValue().

  * à la ligne 23, je teste si ma méthode getCookieValue() a retourné une valeur ou non ;

  * de la ligne 24 à la ligne 43, je traite les dates grâce aux méthodes de la bibliothèque JodaTime. Je vous recommande
    fortement d'aller vous-mêmes parcourir son guide d'utilisation ainsi que sa FAQ. C'est en anglais, mais les codes
    d'exemples sont très explicites. Voici quelques détails en supplément des commentaires déjà présents dans le code de
    la servlet :

        . j'ai pris pour convention le format "dd/MM/yyyy HH:mm:ss", et considère donc que la date sera stockée sous
          ce format dans le cookie derniereConnexion placé dans le navigateur du client ;

        . les lignes 27 et 28 permettent de traduire la date présente au format texte dans le cookie du client en un
          objet DateTime que nous utiliserons par la suite pour effectuer la différence avec la date courante ;

        . à la ligne 30, je calcule la différence entre la date courante et la date de la dernière visite, c'est-à-dire
          l'intervalle de temps écoulé ;

        . de la ligne 32 à 40, je crée un format d'affichage de mon choix à l'aide de l'objet PeriodFormatterBuilder ;

        . à la ligne 41 j'enregistre dans un String, via la méthode print(), l'intervalle mis en forme avec le format
          que j'ai fraîchement défini ;

        . enfin à la ligne 43, je transmets l'intervalle mis en forme à notre JSP, via un simple attribut de requête
          nommé intervalleConnexions.

En fin de compte, si vous mettez de côté la tambouille que nous réalisons pour manipuler nos dates et calculer
l'intervalle entre deux connexions, vous vous rendrez compte que le traitement lié au cookie en lui-même est assez court :
il suffit simplement de vérifier le retour de la méthode request.getCookies(), chose que nous faisons ici grâce à notre
méthode getCookieValue().


--%>

</body>
</html>
