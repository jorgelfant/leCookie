package com.exemple.servlets;

import com.exemple.beans.Utilisateur;
import com.exemple.forms.ConnexionForm;
import org.joda.time.DateTime;
import org.joda.time.Period;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.PeriodFormatter;
import org.joda.time.format.PeriodFormatterBuilder;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Cookie;
import java.io.IOException;

public class Connexion extends HttpServlet {
    //CONSTANTES FACILITANT LA COMPREHENSION
    public static final String  ATT_USER                  = "utilisateur";
    public static final String  ATT_FORM                  = "form";
    public static final String  ATT_INTERVALLE_CONNEXIONS = "intervalleConnexions";
    public static final String  ATT_SESSION_USER          = "sessionUtilisateur";
    public static final String  COOKIE_DERNIERE_CONNEXION = "derniereConnexion";
    public static final String  FORMAT_DATE               = "dd/MM/yyyy HH:mm:ss";
    public static final String  VUE                       = "/WEB-INF/connexion.jsp";


    //******************************************************************************************************************
    //    Méthode doGet
    //******************************************************************************************************************
    public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Tentative de récupération du cookie depuis la requête
        String derniereConnexion = getCookieValue( request, COOKIE_DERNIERE_CONNEXION );
        // Si le cookie existe, alors calcul de la durée
        if ( derniereConnexion != null ) {
            // Récupération de la date courante
            DateTime dtCourante = new DateTime();
            // Récupération de la date présente dans le cookie
            DateTimeFormatter formatter = DateTimeFormat.forPattern( FORMAT_DATE );
            DateTime dtDerniereConnexion = formatter.parseDateTime( derniereConnexion );
            // Calcul de la durée de l'intervalle
            Period periode = new Period( dtDerniereConnexion, dtCourante );
            // Formatage de la durée de l'intervalle
            PeriodFormatter periodFormatter = new PeriodFormatterBuilder()
                    .appendYears().appendSuffix( " an ", " ans " )
                    .appendMonths().appendSuffix( " mois " )
                    .appendDays().appendSuffix( " jour ", " jours " )
                    .appendHours().appendSuffix( " heure ", " heures " )
                    .appendMinutes().appendSuffix( " minute ", " minutes " )
                    .appendSeparator( "et " )
                    .appendSeconds().appendSuffix( " seconde", " secondes" )
                    .toFormatter();
            String intervalleConnexions = periodFormatter.print( periode );
            // Ajout de l'intervalle en tant qu'attribut de la requête
            request.setAttribute( ATT_INTERVALLE_CONNEXIONS, intervalleConnexions );
        }
        // Affichage de la page de connexion
        this.getServletContext().getRequestDispatcher( VUE ).forward( request, response );
    }

    //******************************************************************************************************************
    //    Méthode doPost
    //******************************************************************************************************************
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Préparation de l'objet formulaire
        ConnexionForm form = new ConnexionForm();

        // Traitement de la requête et récupération du bean en résultant
        Utilisateur utilisateur = form.connecterUtilisateur(request);

        // Récupération de la session depuis la requête
        HttpSession session = request.getSession();

        // Si aucune erreur de validation n'a eu lieu, alors ajout du bean Utilisateur à la session, sinon suppression
        // du bean de la session.
        if (form.getErreurs().isEmpty()) {
            //if (session.isNew()) {
            session.setAttribute(ATT_SESSION_USER, utilisateur);
            //}
        } else {
            session.setAttribute(ATT_SESSION_USER, null);
        }

        // Stockage du formulaire et du bean dans l'objet request
        request.setAttribute(ATT_FORM, form);
        request.setAttribute(ATT_USER, utilisateur);

        this.getServletContext().getRequestDispatcher(VUE).forward(request, response);
    }

    //******************************************************************************************************************
    //    Méthode utilitaire gérant la récupération de la valeur d'un cookie donné depuis la requête HTTP.
    //******************************************************************************************************************

    private static String getCookieValue( HttpServletRequest request, String nom ) {
        Cookie[] cookies = request.getCookies();
        if ( cookies != null ) {
            for ( Cookie cookie : cookies ) {
                if ( cookie != null && nom.equals( cookie.getName() ) ) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }
}
