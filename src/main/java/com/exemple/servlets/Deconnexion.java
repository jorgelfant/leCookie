package com.exemple.servlets;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class Deconnexion extends HttpServlet {
    public static final String VUE = "/connexion";
    public static final String URL_REDIRECTION = "http://www.siteduzero.com";

    public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {


        /* Récupération et destruction de la session en cours */
        HttpSession session = request.getSession();
        session.invalidate();//la méthode invalidate() sert à détruire une session manuellement

        /* 1) CAS DE REDIRECTION URL EXTERNES Redirection vers le Site du Zéro !
           la redirection vers la page de connexion via la méthode sendRedirect() de l'objet HttpServletResponse,
           en lieu et place du forwarding que nous utilisions auparavant. le client le voit dans le navigateur
           il es possible de faire ceci avec les pages externet mais aussi côté client en passant par le navigateur
           a condition de mettre le chemin complet cad le nomDuProjet/servlet     /session_war_exploded/connexion*/

        // response.sendRedirect("/session_war_exploded/connexion");
        response.sendRedirect(URL_REDIRECTION);

        /*2) CAS DE FORWARDING  REDIRECTION VER PAGES INTERNES A L'APPLICATION Affichage de la page de connexion
             côté serveur, le client ne sait pas qu'il est redirigé
             l'url ne change pas et meme si on est envoyé à la page jsp connexion, l'url continue d'afficher deconnexion
             http://localhost:8080/session_war_exploded/deconnexion */
        // this.getServletContext().getRequestDispatcher(VUE).forward(request, response);

    }
}
